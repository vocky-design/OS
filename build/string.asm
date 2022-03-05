
./build/string.o:     file format elf32-i386


Disassembly of section .text:

00000000 <memset>:
#include "string.h"
#include "stdint.h"
#include "debug.h"
void memset(void *dst_, uint8_t value, uint32_t size)
{
   0:	55                   	push   ebp
   1:	89 e5                	mov    ebp,esp
   3:	83 ec 28             	sub    esp,0x28
   6:	8b 45 0c             	mov    eax,DWORD PTR [ebp+0xc]
   9:	88 45 e4             	mov    BYTE PTR [ebp-0x1c],al
    ASSERT(dst_ != NULL);
   c:	83 7d 08 00          	cmp    DWORD PTR [ebp+0x8],0x0
  10:	75 19                	jne    2b <memset+0x2b>
  12:	68 00 00 00 00       	push   0x0
  17:	68 90 00 00 00       	push   0x90
  1c:	6a 06                	push   0x6
  1e:	68 0d 00 00 00       	push   0xd
  23:	e8 fc ff ff ff       	call   24 <memset+0x24>
  28:	83 c4 10             	add    esp,0x10
    uint8_t *dst = (uint8_t *)dst_;
  2b:	8b 45 08             	mov    eax,DWORD PTR [ebp+0x8]
  2e:	89 45 f4             	mov    DWORD PTR [ebp-0xc],eax
    while(size--) {
  31:	eb 0f                	jmp    42 <memset+0x42>
        *dst++ = value;
  33:	8b 45 f4             	mov    eax,DWORD PTR [ebp-0xc]
  36:	8d 50 01             	lea    edx,[eax+0x1]
  39:	89 55 f4             	mov    DWORD PTR [ebp-0xc],edx
  3c:	0f b6 55 e4          	movzx  edx,BYTE PTR [ebp-0x1c]
  40:	88 10                	mov    BYTE PTR [eax],dl
#include "debug.h"
void memset(void *dst_, uint8_t value, uint32_t size)
{
    ASSERT(dst_ != NULL);
    uint8_t *dst = (uint8_t *)dst_;
    while(size--) {
  42:	8b 45 10             	mov    eax,DWORD PTR [ebp+0x10]
  45:	8d 50 ff             	lea    edx,[eax-0x1]
  48:	89 55 10             	mov    DWORD PTR [ebp+0x10],edx
  4b:	85 c0                	test   eax,eax
  4d:	75 e4                	jne    33 <memset+0x33>
        *dst++ = value;
    }
}
  4f:	90                   	nop
  50:	c9                   	leave  
  51:	c3                   	ret    

00000052 <memcpy>:
void memcpy(void *dst_, const void *src_, uint32_t size)
{
  52:	55                   	push   ebp
  53:	89 e5                	mov    ebp,esp
  55:	83 ec 18             	sub    esp,0x18
    ASSERT(dst_ != NULL && src_ != NULL);
  58:	83 7d 08 00          	cmp    DWORD PTR [ebp+0x8],0x0
  5c:	74 06                	je     64 <memcpy+0x12>
  5e:	83 7d 0c 00          	cmp    DWORD PTR [ebp+0xc],0x0
  62:	75 19                	jne    7d <memcpy+0x2b>
  64:	68 1a 00 00 00       	push   0x1a
  69:	68 98 00 00 00       	push   0x98
  6e:	6a 0e                	push   0xe
  70:	68 0d 00 00 00       	push   0xd
  75:	e8 fc ff ff ff       	call   76 <memcpy+0x24>
  7a:	83 c4 10             	add    esp,0x10
    uint8_t *dst = (uint8_t*)dst_;
  7d:	8b 45 08             	mov    eax,DWORD PTR [ebp+0x8]
  80:	89 45 f4             	mov    DWORD PTR [ebp-0xc],eax
    const uint8_t *src = (uint8_t*)src_;
  83:	8b 45 0c             	mov    eax,DWORD PTR [ebp+0xc]
  86:	89 45 f0             	mov    DWORD PTR [ebp-0x10],eax
    while (size--) {
  89:	eb 17                	jmp    a2 <memcpy+0x50>
        *dst++ = *src++;
  8b:	8b 45 f4             	mov    eax,DWORD PTR [ebp-0xc]
  8e:	8d 50 01             	lea    edx,[eax+0x1]
  91:	89 55 f4             	mov    DWORD PTR [ebp-0xc],edx
  94:	8b 55 f0             	mov    edx,DWORD PTR [ebp-0x10]
  97:	8d 4a 01             	lea    ecx,[edx+0x1]
  9a:	89 4d f0             	mov    DWORD PTR [ebp-0x10],ecx
  9d:	0f b6 12             	movzx  edx,BYTE PTR [edx]
  a0:	88 10                	mov    BYTE PTR [eax],dl
void memcpy(void *dst_, const void *src_, uint32_t size)
{
    ASSERT(dst_ != NULL && src_ != NULL);
    uint8_t *dst = (uint8_t*)dst_;
    const uint8_t *src = (uint8_t*)src_;
    while (size--) {
  a2:	8b 45 10             	mov    eax,DWORD PTR [ebp+0x10]
  a5:	8d 50 ff             	lea    edx,[eax-0x1]
  a8:	89 55 10             	mov    DWORD PTR [ebp+0x10],edx
  ab:	85 c0                	test   eax,eax
  ad:	75 dc                	jne    8b <memcpy+0x39>
        *dst++ = *src++;
    }
}
  af:	90                   	nop
  b0:	c9                   	leave  
  b1:	c3                   	ret    

000000b2 <memcmp>:
//*a>*b返回1，*a<*b返回-1，*a==*b返回0
int8_t memcmp(const void *a_, const void *b_, uint32_t size)
{
  b2:	55                   	push   ebp
  b3:	89 e5                	mov    ebp,esp
  b5:	83 ec 18             	sub    esp,0x18
    ASSERT(a_ != NULL && b_ != NULL);
  b8:	83 7d 08 00          	cmp    DWORD PTR [ebp+0x8],0x0
  bc:	74 06                	je     c4 <memcmp+0x12>
  be:	83 7d 0c 00          	cmp    DWORD PTR [ebp+0xc],0x0
  c2:	75 19                	jne    dd <memcmp+0x2b>
  c4:	68 37 00 00 00       	push   0x37
  c9:	68 a0 00 00 00       	push   0xa0
  ce:	6a 18                	push   0x18
  d0:	68 0d 00 00 00       	push   0xd
  d5:	e8 fc ff ff ff       	call   d6 <memcmp+0x24>
  da:	83 c4 10             	add    esp,0x10
    const uint8_t *a = (uint8_t*)a_;
  dd:	8b 45 08             	mov    eax,DWORD PTR [ebp+0x8]
  e0:	89 45 f4             	mov    DWORD PTR [ebp-0xc],eax
    const uint8_t *b = (uint8_t*)b_;
  e3:	8b 45 0c             	mov    eax,DWORD PTR [ebp+0xc]
  e6:	89 45 f0             	mov    DWORD PTR [ebp-0x10],eax
    while(size--) {
  e9:	eb 36                	jmp    121 <memcmp+0x6f>
        if(*a != *b) {
  eb:	8b 45 f4             	mov    eax,DWORD PTR [ebp-0xc]
  ee:	0f b6 10             	movzx  edx,BYTE PTR [eax]
  f1:	8b 45 f0             	mov    eax,DWORD PTR [ebp-0x10]
  f4:	0f b6 00             	movzx  eax,BYTE PTR [eax]
  f7:	38 c2                	cmp    dl,al
  f9:	74 1e                	je     119 <memcmp+0x67>
            return *a>*b ? 1:-1; 
  fb:	8b 45 f4             	mov    eax,DWORD PTR [ebp-0xc]
  fe:	0f b6 10             	movzx  edx,BYTE PTR [eax]
 101:	8b 45 f0             	mov    eax,DWORD PTR [ebp-0x10]
 104:	0f b6 00             	movzx  eax,BYTE PTR [eax]
 107:	38 c2                	cmp    dl,al
 109:	76 07                	jbe    112 <memcmp+0x60>
 10b:	b8 01 00 00 00       	mov    eax,0x1
 110:	eb 21                	jmp    133 <memcmp+0x81>
 112:	b8 ff ff ff ff       	mov    eax,0xffffffff
 117:	eb 1a                	jmp    133 <memcmp+0x81>
        }
        a++;
 119:	83 45 f4 01          	add    DWORD PTR [ebp-0xc],0x1
        b++;
 11d:	83 45 f0 01          	add    DWORD PTR [ebp-0x10],0x1
int8_t memcmp(const void *a_, const void *b_, uint32_t size)
{
    ASSERT(a_ != NULL && b_ != NULL);
    const uint8_t *a = (uint8_t*)a_;
    const uint8_t *b = (uint8_t*)b_;
    while(size--) {
 121:	8b 45 10             	mov    eax,DWORD PTR [ebp+0x10]
 124:	8d 50 ff             	lea    edx,[eax-0x1]
 127:	89 55 10             	mov    DWORD PTR [ebp+0x10],edx
 12a:	85 c0                	test   eax,eax
 12c:	75 bd                	jne    eb <memcmp+0x39>
            return *a>*b ? 1:-1; 
        }
        a++;
        b++;
    }
    return 0;
 12e:	b8 00 00 00 00       	mov    eax,0x0
}
 133:	c9                   	leave  
 134:	c3                   	ret    

00000135 <strcpy>:

char *strcpy(char *dst, const char *src)
{
 135:	55                   	push   ebp
 136:	89 e5                	mov    ebp,esp
 138:	83 ec 18             	sub    esp,0x18
    ASSERT(dst != NULL && src != NULL);
 13b:	83 7d 08 00          	cmp    DWORD PTR [ebp+0x8],0x0
 13f:	74 06                	je     147 <strcpy+0x12>
 141:	83 7d 0c 00          	cmp    DWORD PTR [ebp+0xc],0x0
 145:	75 19                	jne    160 <strcpy+0x2b>
 147:	68 50 00 00 00       	push   0x50
 14c:	68 a8 00 00 00       	push   0xa8
 151:	6a 27                	push   0x27
 153:	68 0d 00 00 00       	push   0xd
 158:	e8 fc ff ff ff       	call   159 <strcpy+0x24>
 15d:	83 c4 10             	add    esp,0x10
    char *p = dst;
 160:	8b 45 08             	mov    eax,DWORD PTR [ebp+0x8]
 163:	89 45 f4             	mov    DWORD PTR [ebp-0xc],eax
    while((*dst++ = *src++));
 166:	90                   	nop
 167:	8b 45 08             	mov    eax,DWORD PTR [ebp+0x8]
 16a:	8d 50 01             	lea    edx,[eax+0x1]
 16d:	89 55 08             	mov    DWORD PTR [ebp+0x8],edx
 170:	8b 55 0c             	mov    edx,DWORD PTR [ebp+0xc]
 173:	8d 4a 01             	lea    ecx,[edx+0x1]
 176:	89 4d 0c             	mov    DWORD PTR [ebp+0xc],ecx
 179:	0f b6 12             	movzx  edx,BYTE PTR [edx]
 17c:	88 10                	mov    BYTE PTR [eax],dl
 17e:	0f b6 00             	movzx  eax,BYTE PTR [eax]
 181:	84 c0                	test   al,al
 183:	75 e2                	jne    167 <strcpy+0x32>
    return p;
 185:	8b 45 f4             	mov    eax,DWORD PTR [ebp-0xc]
}
 188:	c9                   	leave  
 189:	c3                   	ret    

0000018a <strlen>:
uint32_t strlen(const char *str)
{
 18a:	55                   	push   ebp
 18b:	89 e5                	mov    ebp,esp
 18d:	83 ec 18             	sub    esp,0x18
    ASSERT(str != NULL);
 190:	83 7d 08 00          	cmp    DWORD PTR [ebp+0x8],0x0
 194:	75 19                	jne    1af <strlen+0x25>
 196:	68 6b 00 00 00       	push   0x6b
 19b:	68 b0 00 00 00       	push   0xb0
 1a0:	6a 2e                	push   0x2e
 1a2:	68 0d 00 00 00       	push   0xd
 1a7:	e8 fc ff ff ff       	call   1a8 <strlen+0x1e>
 1ac:	83 c4 10             	add    esp,0x10
    const char *p = str;
 1af:	8b 45 08             	mov    eax,DWORD PTR [ebp+0x8]
 1b2:	89 45 f4             	mov    DWORD PTR [ebp-0xc],eax
    while(*str++);
 1b5:	90                   	nop
 1b6:	8b 45 08             	mov    eax,DWORD PTR [ebp+0x8]
 1b9:	8d 50 01             	lea    edx,[eax+0x1]
 1bc:	89 55 08             	mov    DWORD PTR [ebp+0x8],edx
 1bf:	0f b6 00             	movzx  eax,BYTE PTR [eax]
 1c2:	84 c0                	test   al,al
 1c4:	75 f0                	jne    1b6 <strlen+0x2c>
    return str-p-1;
 1c6:	8b 55 08             	mov    edx,DWORD PTR [ebp+0x8]
 1c9:	8b 45 f4             	mov    eax,DWORD PTR [ebp-0xc]
 1cc:	29 c2                	sub    edx,eax
 1ce:	89 d0                	mov    eax,edx
 1d0:	83 e8 01             	sub    eax,0x1
}
 1d3:	c9                   	leave  
 1d4:	c3                   	ret    

000001d5 <strcmp>:
int8_t strcmp(const char *a, const char *b)
{
 1d5:	55                   	push   ebp
 1d6:	89 e5                	mov    ebp,esp
 1d8:	83 ec 08             	sub    esp,0x8
    ASSERT(a != NULL && b != NULL);
 1db:	83 7d 08 00          	cmp    DWORD PTR [ebp+0x8],0x0
 1df:	74 06                	je     1e7 <strcmp+0x12>
 1e1:	83 7d 0c 00          	cmp    DWORD PTR [ebp+0xc],0x0
 1e5:	75 19                	jne    200 <strcmp+0x2b>
 1e7:	68 77 00 00 00       	push   0x77
 1ec:	68 b8 00 00 00       	push   0xb8
 1f1:	6a 35                	push   0x35
 1f3:	68 0d 00 00 00       	push   0xd
 1f8:	e8 fc ff ff ff       	call   1f9 <strcmp+0x24>
 1fd:	83 c4 10             	add    esp,0x10
    while(*a != 0 || *a == *b) {
 200:	eb 08                	jmp    20a <strcmp+0x35>
        a++;
 202:	83 45 08 01          	add    DWORD PTR [ebp+0x8],0x1
        b++;
 206:	83 45 0c 01          	add    DWORD PTR [ebp+0xc],0x1
    return str-p-1;
}
int8_t strcmp(const char *a, const char *b)
{
    ASSERT(a != NULL && b != NULL);
    while(*a != 0 || *a == *b) {
 20a:	8b 45 08             	mov    eax,DWORD PTR [ebp+0x8]
 20d:	0f b6 00             	movzx  eax,BYTE PTR [eax]
 210:	84 c0                	test   al,al
 212:	75 ee                	jne    202 <strcmp+0x2d>
 214:	8b 45 08             	mov    eax,DWORD PTR [ebp+0x8]
 217:	0f b6 10             	movzx  edx,BYTE PTR [eax]
 21a:	8b 45 0c             	mov    eax,DWORD PTR [ebp+0xc]
 21d:	0f b6 00             	movzx  eax,BYTE PTR [eax]
 220:	38 c2                	cmp    dl,al
 222:	74 de                	je     202 <strcmp+0x2d>
        a++;
        b++;
    }
    return *a<*b ? -1:*a>*b ;
 224:	8b 45 08             	mov    eax,DWORD PTR [ebp+0x8]
 227:	0f b6 10             	movzx  edx,BYTE PTR [eax]
 22a:	8b 45 0c             	mov    eax,DWORD PTR [ebp+0xc]
 22d:	0f b6 00             	movzx  eax,BYTE PTR [eax]
 230:	38 c2                	cmp    dl,al
 232:	7c 13                	jl     247 <strcmp+0x72>
 234:	8b 45 08             	mov    eax,DWORD PTR [ebp+0x8]
 237:	0f b6 10             	movzx  edx,BYTE PTR [eax]
 23a:	8b 45 0c             	mov    eax,DWORD PTR [ebp+0xc]
 23d:	0f b6 00             	movzx  eax,BYTE PTR [eax]
 240:	38 c2                	cmp    dl,al
 242:	0f 9f c0             	setg   al
 245:	eb 05                	jmp    24c <strcmp+0x77>
 247:	b8 ff ff ff ff       	mov    eax,0xffffffff
}
 24c:	c9                   	leave  
 24d:	c3                   	ret    

0000024e <strchr>:
char *strchr(const char *str, const char ch)
{
 24e:	55                   	push   ebp
 24f:	89 e5                	mov    ebp,esp
 251:	83 ec 18             	sub    esp,0x18
 254:	8b 45 0c             	mov    eax,DWORD PTR [ebp+0xc]
 257:	88 45 f4             	mov    BYTE PTR [ebp-0xc],al
    ASSERT(str != NULL);
 25a:	83 7d 08 00          	cmp    DWORD PTR [ebp+0x8],0x0
 25e:	75 2f                	jne    28f <strchr+0x41>
 260:	68 6b 00 00 00       	push   0x6b
 265:	68 c0 00 00 00       	push   0xc0
 26a:	6a 3e                	push   0x3e
 26c:	68 0d 00 00 00       	push   0xd
 271:	e8 fc ff ff ff       	call   272 <strchr+0x24>
 276:	83 c4 10             	add    esp,0x10
    while(*str) {
 279:	eb 14                	jmp    28f <strchr+0x41>
        if(*str == ch) {
 27b:	8b 45 08             	mov    eax,DWORD PTR [ebp+0x8]
 27e:	0f b6 00             	movzx  eax,BYTE PTR [eax]
 281:	3a 45 f4             	cmp    al,BYTE PTR [ebp-0xc]
 284:	75 05                	jne    28b <strchr+0x3d>
            return (char *)str;
 286:	8b 45 08             	mov    eax,DWORD PTR [ebp+0x8]
 289:	eb 13                	jmp    29e <strchr+0x50>
        }
        ++str;
 28b:	83 45 08 01          	add    DWORD PTR [ebp+0x8],0x1
    return *a<*b ? -1:*a>*b ;
}
char *strchr(const char *str, const char ch)
{
    ASSERT(str != NULL);
    while(*str) {
 28f:	8b 45 08             	mov    eax,DWORD PTR [ebp+0x8]
 292:	0f b6 00             	movzx  eax,BYTE PTR [eax]
 295:	84 c0                	test   al,al
 297:	75 e2                	jne    27b <strchr+0x2d>
        if(*str == ch) {
            return (char *)str;
        }
        ++str;
    }
    return NULL;
 299:	b8 00 00 00 00       	mov    eax,0x0
 29e:	c9                   	leave  
 29f:	c3                   	ret    
