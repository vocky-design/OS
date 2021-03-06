;-----------------------loader-------------------------
LOADER_START_SECTOR 	equ 0x2
LOADER_BASE_ADDR 		equ 0x900

PAGE_DIR_TABLE_POS 		equ 0x100000

KERNEL_START_SECTOR		equ	0x9
KERNEL_BIN_BASE_ADDR	equ 0x70000

KERNEL_ENTRY_POINT		equ	0xc0001500		;需要与ld的-Ttext参数一致。
;-----------------------gdt描述符属性------------------
DESC_G_4K 			equ 		10000000_00000000_00000000b
DESC_D_32 			equ  		 1000000_00000000_00000000b
DESC_L_32 			equ   		  000000_00000000_00000000b
DESC_AVL  			equ    		   00000_00000000_00000000b
DESC_LIMIT_CODE2 	equ 			1111_00000000_00000000b
DESC_LIMIT_DATA2 	equ				DESC_LIMIT_CODE2
DESC_LIMIT_VIDEO2	equ				0000_00000000_00000000b
DESC_P				equ				     10000000_00000000b
DESC_DPL_0			equ					  0000000_00000000b
DESC_DPL_1			equ					  0100000_00000000b
DESC_DPL_2			equ					  1000000_00000000b
DESC_DPL_3			equ					  1100000_00000000b
DESC_S_CODE			equ						10000_00000000b
DESC_S_DATA			equ						DESC_S_CODE
DESC_S_SYS			equ						00000_00000000b
DESC_TYPE_CODE		equ						 1000_00000000b
DESC_TYPE_DATA      equ						 0010_00000000b
;;;;;; 
DESC_CODE_HIGH4		equ (0x00<<24) + DESC_G_4K + DESC_D_32 + DESC_L_32 + DESC_AVL + \
					DESC_LIMIT_CODE2 + DESC_P + DESC_DPL_0 + DESC_S_CODE + \
					DESC_TYPE_CODE + 0X00
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     
DESC_DATA_HIGH4 	equ (0x00<<24) + DESC_G_4K + DESC_D_32 + DESC_L_32 + DESC_AVL + \
					DESC_LIMIT_DATA2 + DESC_P + DESC_DPL_0 + DESC_S_DATA + \
					DESC_TYPE_DATA + 0x00

DESC_VIDEO_HIGH4 	equ (0x00<<24) + DESC_G_4K + DESC_D_32 + DESC_L_32 + DESC_AVL + \
					DESC_LIMIT_VIDEO2 + DESC_P + DESC_DPL_0 + DESC_S_DATA + \
					DESC_TYPE_DATA + 0x0b
;-----------------------选择子属性----------------------
RPL0 	equ 	00b
RPL1 	equ 	01b
RPL2 	equ 	10b
RPL3 	equ 	11b	
TI_GDT	equ		0_00b
TI_LDT	equ		1_00b	
;-----------------------页表相关属性--------------------
PG_P	equ		1b
PG_RW_R	equ		00b
PG_RW_W	equ		10b
PG_US_S equ		000b
PG_US_U	equ		100b

;-----------------------ELF文件分析---------------------
PT_NULL	equ 	0

