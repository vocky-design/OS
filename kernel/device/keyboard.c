#include "keyboard.h"
#include "stdint.h"
#include "print.h"
#include "io.h"
#include "interrupt.h"
#include "ioqueue.h"

//定义一个环形缓冲队列
struct ioqueue kbd_buf;

#define KBD_BUF_PORT 0x60       //键盘buffer寄存器端口号

/* 字符控制的转移字符 */
#define esc         '\033'
#define backspace   '\b'
#define tab         '\t'
#define enter       '\r'
#define delete      '\177'

/* 非字符控制的其他控制 */
#define char_invisible  0
#define ctrl_l_char     char_invisible
#define ctrl_r_char     char_invisible
#define shift_l_char    char_invisible
#define shift_r_char    char_invisible
#define alt_l_char      char_invisible
#define alt_r_char      char_invisible
#define caps_lock_char  char_invisible

#define shift_l_make    0x2a
#define shift_r_make    0x36
#define alt_l_make      0x38
#define alt_r_make      0xe038
#define alt_r_break     0xe0b8
#define ctrl_l_make     0x1d
#define ctrl_r_make     0xe01d
#define ctrl_r_break    0xe09d
#define caps_lock_make  0x3a

/* 用作记录上一个按键码的全局变量 */
static bool ctrl_status, shift_status, alt_status, caps_lock_status, ext_scancode;
/* 以通码make_code为索引的二维数组 */
/* 与shift键不按下和按下的区别 */
static char keymap[][2] = {
    {0,             0},                 //0x00
    {esc,           esc},               //0x01
    {'1',           '!'},               //0x02
    {'2',           '@'},               //0x03
    {'3',           '#'},               //0x04
    {'4',           '$'},               //0x05
    {'5',           '%'},               //0x06
    {'6',           '^'},               //0x07
    {'7',           '&'},               //0x08
    {'8',           '*'},               //0x09
    {'9',           '('},               //0x0a
    {'0',           ')'},               //0x0b
    {'-',           '_'},               //0x0c
    {'=',           '+'},               //0x0d
    {backspace,     backspace},         //0x0e
    {tab,           tab},               //0x0f
    {'q',           'Q'},               //0x10
    {'w',           'W'},               //0x11
    {'e',           'E'},               //0x12
    {'r',           'R'},               //0x13
    {'t',           'T'},               //0x14
    {'y',           'Y'},               //0x15
    {'u',           'U'},               //0x16
    {'i',           'I'},               //0x17
    {'o',           'O'},               //0x18
    {'p',           'P'},               //0x19
    {'[',           '{'},               //0x1a
    {']',           '}'},               //0x1b
    {enter,         enter},             //0x1c
    {ctrl_l_char,   ctrl_l_char},       //0x1d
    {'a',           'A'},               //0x1e
    {'s',           'S'},               //0x1f
    {'d',           'D'},               //0x20
    {'f',           'F'},               //0x21
    {'g',           'G'},               //0x22
    {'h',           'H'},               //0x23
    {'j',           'J'},               //0x24
    {'k',           'K'},               //0x25
    {'l',           'L'},               //0x26
    {';',           ':'},               //0x27
    {'\'',          '"'},               //0x28
    {'`',           '~'},               //0x29
    {shift_l_char,  shift_l_char},      //0x2a
    {'\\',          '|'},               //0x2b
    {'z',           'Z'},               //0x2c
    {'x',           'X'},               //0x2d
    {'c',           'C'},               //0x2e
    {'v',           'V'},               //0x2f
    {'b',           'B'},               //0x30
    {'n',           'N'},               //0x31
    {'m',           'M'},               //0x32
    {',',           '<'},               //0x33
    {'.',           '>'},               //0x34
    {'/',           '?'},               //0x35
    {shift_r_char,  shift_r_char},      //0x36
    {'*',           '*'},               //0x37
    {alt_l_char,    alt_l_char},        //0x38
    {' ',           ' '},               //0x39
    {caps_lock_char,caps_lock_char},    //0x3a
    //其他按键暂不处理
};

static void intr_keyboard_handler(void)
{
    bool shift_down_last = shift_status;
    bool caps_lock_last = caps_lock_status;
    bool break_code_flag;

    uint16_t scancode = inb(KBD_BUF_PORT);
    if(scancode == 0xe0) {
        ext_scancode = TRUE;
        return;
    }
    if(ext_scancode) {
        scancode = 0xe000 | scancode;
        ext_scancode = FALSE;
    }

    break_code_flag = 0x0080 & scancode;

    if(break_code_flag) {                           //断码分析部分
        //获取断码的通码
        uint16_t make_code = 0xff7f & scancode;
        if(make_code == ctrl_l_make || make_code == ctrl_r_make) {
            ctrl_status = FALSE;
        } else if(make_code == shift_l_make || make_code == shift_r_make) {
            shift_status = FALSE;
        } else if(make_code == alt_l_make || make_code == alt_r_make) {
            alt_status = FALSE;
        }
        //其他键的断码不需要处理
        return;
    }

    //现在是通码分析部分
    if(scancode == ctrl_l_make || scancode == ctrl_r_make) {
        ctrl_status = TRUE;
    } else if(scancode == shift_l_make || scancode == shift_r_make) {
        shift_status = TRUE;
    } else if(scancode == alt_l_make || scancode == alt_r_make) {
        alt_status = TRUE;
    } else if(scancode == caps_lock_make) {
        caps_lock_status = !caps_lock_status;
    } else if((scancode > 0x00 && scancode <= 0x3a) || scancode == alt_r_make || scancode == ctrl_r_make) {
        bool shift = FALSE;
        //如果是有两个字母的键，那么只有shift键有影响
        if((scancode <= 0x0d && scancode >=0x02) || scancode == 0x27 || scancode == 0x28 || scancode == 0x29 || \
               scancode == 0x33 || scancode == 0x34 || scancode == 0x35 || scancode == 0x1a || scancode == 0x1b || scancode == 0x2b){
            if(shift_down_last) {
                shift = TRUE;
            }    
        } else {    //剩余默认为字母键
            if(shift_down_last && caps_lock_last) {
                shift = FALSE;
            } else if(shift_down_last || caps_lock_last) {
                shift = TRUE;
            } else {
                shift = FALSE;
            }
        }

        uint8_t index = (scancode & 0x00ff);
        char cur_char = keymap[index][shift];
        if(cur_char) {
            if(!ioq_full(&kbd_buf)) {
                put_char(cur_char);         
                ioq_putchar(&kbd_buf, cur_char);
            }
        }
    } else {
        put_str("unknown key\n");
    }
} 

void keyboard_init(void)
{
    put_str("keyboard_init start\n");
    ioqueue_init(&kbd_buf);
    register_handler(0x21, intr_keyboard_handler);
    put_str("keyboard_init done\n");
}


