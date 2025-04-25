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

typedef struct {
    __IO uint32_t UCR;
    __IO uint32_t UDR;
} ULTRA_TypeDef;

typedef struct {
    __IO uint32_t DDR;
    __IO uint32_t DMR;
} DHT_TypeDef;

#define APB_BASEADDR    0x10000000
#define GPOA_BASEADDR   (APB_BASEADDR + 0x1000)
#define GPIB_BASEADDR   (APB_BASEADDR + 0x2000)
#define GPIOC_BASEADDR   (APB_BASEADDR + 0x3000)
#define GPIOD_BASEADDR   (APB_BASEADDR + 0x4000)
#define FND_BASEADDR    (APB_BASEADDR + 0x5000)
#define ULTRA_BASEADDR    (APB_BASEADDR + 0x6000)
#define DHT_BASEADDR    (APB_BASEADDR + 0x7000)

#define GPOA            ((GPO_TypeDef *) GPOA_BASEADDR)
#define GPIB            ((GPI_TypeDef *) GPIB_BASEADDR)
#define GPIOC           ((GPIO_TypeDef *) GPIOC_BASEADDR)
#define GPIOD           ((GPIO_TypeDef *) GPIOD_BASEADDR)
#define FND             ((FND_TypeDef *) FND_BASEADDR)
#define ULTRA           ((ULTRA_TypeDef *) ULTRA_BASEADDR)
#define DHT             ((DHT_TypeDef *) DHT_BASEADDR)

#define GPOA_MODER      *(uint32_t *)(GPOA_BASEADDR + 0x00)
#define GPOA_ODR        *(uint32_t *)(GPOA_BASEADDR + 0x04)
#define GPIB_MODER      *(uint32_t *)(GPIB_BASEADDR + 0x00)
#define GPIB_IDR        *(uint32_t *)(GPIB_BASEADDR + 0x04)

#define POWER_ON    1
#define POWER_OFF   0
#define TEMPERATURE   0
#define HUMIDITY   1
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

void Ultra_init(ULTRA_TypeDef *ultra, uint32_t power);
uint32_t Ultra_read(ULTRA_TypeDef *ultra);

void DHT_init(DHT_TypeDef *dht, uint32_t moder);
uint32_t DHT_read(DHT_TypeDef *dht);


int main(){
    // GPOA_MODER = 0xff;
    // GPIB_MODER = 0x00;
    // GPOA->MODER = 0xff;
    // GPIB->MODER = 0x00;
    LED_init(GPIOC);
    Switch_init(GPIOD);
    FND_init(FND, POWER_ON);
    // Ultra_init(ULTRA, POWER_OFF);
    FND_writeDot(FND, 0);
    
    uint32_t temp = 0;
    uint32_t one = 1;
    uint32_t time_interval = 0;
    uint32_t distance = 0;
    uint32_t temperature = 0;
    uint32_t humidity = 0;
    while(1)
    {
        if (time_interval == 5) FND_writeDot(FND, DOT3);
        else if (time_interval == 10) 
        {
            FND_writeDot(FND, 0);
            time_interval = 0;
        }


        switch(Switch_read(GPIOD))
        {
            case 0x00:
                if(temp == 10000) temp = -1;
                temp++;
                FND_writeData(FND, temp);
                delay(100);
                break;
            case (1 << 7):
                if(temp == 0) temp = 10000;
                temp--;
                FND_writeData(FND, temp);
                delay(100);
                break;
            case (1 << 6):
                Ultra_init(ULTRA, POWER_ON);
                delay(1000);
                distance = Ultra_read(ULTRA);
                FND_writeData(FND, distance);
                Ultra_init(ULTRA, POWER_OFF);
                break;
            case (1 << 5):
                DHT_init(DHT, TEMPERATURE);
                delay(1000);
                temperature = DHT_read(DHT);
                FND_writeData(FND, temperature);
                break;
            case (1 << 4):
                DHT_init(DHT, HUMIDITY);
                delay(1000);
                humidity = DHT_read(DHT);
                FND_writeData(FND, humidity);
                break;
            default:
                FND_writeData(FND, 7777);
                break;
        }
        
        time_interval++;

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
void Ultra_init(ULTRA_TypeDef *ultra, uint32_t power)
{
    ultra->UCR = power;
}
uint32_t Ultra_read(ULTRA_TypeDef *ultra)
{
    return ultra->UDR;
}
void DHT_init(DHT_TypeDef *dht, uint32_t moder)
{
    dht->DMR = moder;
}
uint32_t DHT_read(DHT_TypeDef *dht)
{
    return dht->DDR;
}