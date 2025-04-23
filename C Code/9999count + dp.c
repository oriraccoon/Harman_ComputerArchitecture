#include <stdint.h>

#define __IO            volatile

typedef struct {
    __IO uint32_t MODER;
    __IO uint32_t ODR;
} GPO_TypeDef;

typedef struct {
    __IO uint32_t MODER;
    __IO uint32_t IDR;
} GPI_TypeDef;

typedef struct {
    __IO uint32_t MODER;
    __IO uint32_t IDR;
    __IO uint32_t ODR;
} GPIO_TypeDef;

typedef struct {
    __IO uint32_t FCR;
    __IO uint32_t FDR;
    __IO uint32_t FPR;
} FND_TypeDef;

#define APB_BASEADDR    0x10000000
#define GPOA_BASEADDR   (APB_BASEADDR + 0x1000)
#define GPIB_BASEADDR   (APB_BASEADDR + 0x2000)
#define GPIOC_BASEADDR   (APB_BASEADDR + 0x3000)
#define GPIOD_BASEADDR   (APB_BASEADDR + 0x4000)
#define FND_BASEADDR    (APB_BASEADDR + 0x5000)

#define GPOA            ((GPO_TypeDef *) GPOA_BASEADDR)
#define GPIB            ((GPI_TypeDef *) GPIB_BASEADDR)
#define GPIOC           ((GPIO_TypeDef *) GPIOC_BASEADDR)
#define GPIOD           ((GPIO_TypeDef *) GPIOD_BASEADDR)
#define FND             ((FND_TypeDef *) FND_BASEADDR)

#define GPOA_MODER      *(uint32_t *)(GPOA_BASEADDR + 0x00)
#define GPOA_ODR        *(uint32_t *)(GPOA_BASEADDR + 0x04)
#define GPIB_MODER      *(uint32_t *)(GPIB_BASEADDR + 0x00)
#define GPIB_IDR        *(uint32_t *)(GPIB_BASEADDR + 0x04)

#define FND_POWER_ON    1
#define FND_POWER_OFF   0
#define DOT4   (1<<3)
#define DOT3   (1<<2)
#define DOT2   (1<<1)
#define DOT1   (1<<0)


void delay(int n);

void LED_init(GPIO_TypeDef *GPIOx);
void LED_write(GPIO_TypeDef *GPIOx, uint32_t data);

void Switch_init(GPIO_TypeDef *GPIOx);
uint32_t Switch_read(GPIO_TypeDef *GPIOx);

void FND_init(FND_TypeDef *fnd, uint32_t power);
void FND_writeData(FND_TypeDef *fnd, uint32_t data);
void FND_writeDot(FND_TypeDef *fnd, uint32_t dot);


int main(){
    // GPOA_MODER = 0xff;
    // GPIB_MODER = 0x00;
    // GPOA->MODER = 0xff;
    // GPIB->MODER = 0x00;
    LED_init(GPIOC);
    Switch_init(GPIOD);
    FND_init(FND, FND_POWER_ON);
    FND_writeDot(FND, 0);
    
    uint32_t temp = 0;
    uint32_t one = 1;
    uint32_t time_interval = 0;
    while(1)
    {
        while(temp < 10000)
        {
            if (time_interval == 5) FND_writeDot(FND, DOT3);
            else if (time_interval == 10) 
            {
                FND_writeDot(FND, 0);
                time_interval = 0;
            }
            if (Switch_read(GPIOD) == 0x80)
            {
                FND_writeData(FND, temp);
                temp--;
                delay(100);
            }
            else if (Switch_read(GPIOD) == 0x00)
            {
                FND_writeData(FND, temp);
                temp++;
                delay(100);
            }

            time_interval++;
        }

        temp = 0;

        // temp = Switch_read(GPIOD);
        // if (temp & (1<<0)){
        //    LED_write(GPIOC, temp); 
        // }
        // else if (temp & (1<<1)){
        //     LED_write(GPIOC, one);
        //     one = (one << 1) | (one >> 7);
        //     delay(500);
        // }
        // else if (temp & (1<<2)){
        //     LED_write(GPIOC, one);
        //     one = (one << 1) | (one >> 7);
        //     delay(500);
        // }
        // else{
        //     LED_write(GPIOC, 0xff);
        //     delay(500);
        //     LED_write(GPIOC, 0x00);
        //     delay(500);
        // }
        // GPOA_ODR = GPIB_IDR;
        // GPOA->ODR = GPIB->IDR;
        // GPOA_ODR = 0xff;
        // delay(500);
        // GPOA_ODR = 0x00;
        // delay(500);
    }
    return 0;
}

void delay(int n){
    uint32_t temp = 0;
    for (int i = 0; i < n; i++){
        for (int j = 0; j < 1000; j++){
            temp++;
        }
    }
}

void LED_init(GPIO_TypeDef *GPIOx){
    GPIOx->MODER = 0xff;
}

void LED_write(GPIO_TypeDef *GPIOx, uint32_t data){
    GPIOx->ODR = data;
}

void Switch_init(GPIO_TypeDef *GPIOx){
    GPIOx->MODER = 0x00;
}

uint32_t Switch_read(GPIO_TypeDef *GPIOx){
    return GPIOx->IDR;
}

void FND_init(FND_TypeDef *fnd, uint32_t power)
{
    fnd->FCR = power;
}
void FND_writeData(FND_TypeDef *fnd, uint32_t data)
{
    fnd->FDR = data;
}
void FND_writeDot(FND_TypeDef *fnd, uint32_t dot)
{
    fnd->FPR = dot;
}