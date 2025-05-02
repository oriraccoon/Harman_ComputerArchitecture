#include <stdint.h>

#define __IO            volatile

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
    __IO uint32_t BDR;
    // __IO uint32_t PDR;
} BLINK_TypeDef;

typedef struct {
    __IO uint32_t DDR;
    __IO uint32_t DMR;
} DHT_TypeDef;

typedef struct {
    __IO uint32_t TCNR;
    __IO uint32_t TCR;
    __IO uint32_t PSC;
    __IO uint32_t ARR;
} TIMER_TypeDef;

#define APB_BASEADDR    0x10000000
#define TIMER_BASEADDR     (APB_BASEADDR + 0x1000)
#define GPIOB_BASEADDR   (APB_BASEADDR + 0x2000)
#define GPIOC_BASEADDR   (APB_BASEADDR + 0x3000)
#define GPIOD_BASEADDR   (APB_BASEADDR + 0x4000)
#define FND_BASEADDR    (APB_BASEADDR + 0x5000)
#define ULTRA_BASEADDR    (APB_BASEADDR + 0x6000)
#define DHT_BASEADDR    (APB_BASEADDR + 0x7000)
#define BLINK_BASEADDR    (APB_BASEADDR + 0x8000)
#define TIMER2_BASEADDR     (APB_BASEADDR + 0x9000)

#define TIMER            ((TIMER_TypeDef *) TIMER_BASEADDR)
#define GPIOB            ((GPIO_TypeDef *) GPIOB_BASEADDR)
#define GPIOC           ((GPIO_TypeDef *) GPIOC_BASEADDR)
#define GPIOD           ((GPIO_TypeDef *) GPIOD_BASEADDR)
#define FND             ((FND_TypeDef *) FND_BASEADDR)
#define ULTRA           ((ULTRA_TypeDef *) ULTRA_BASEADDR)
#define DHT             ((DHT_TypeDef *) DHT_BASEADDR)
#define BLINK           ((BLINK_TypeDef *) BLINK_BASEADDR)
#define TIMER2            ((TIMER_TypeDef *) TIMER2_BASEADDR)

#define POWER_ON    1
#define POWER_OFF   0
#define TEMPERATURE   0
#define HUMIDITY   1

#define LEFT  16000
#define RIGHT  16001
#define BOTH  16002


#define F_CPU 100000000

void switch_case_func(GPIO_TypeDef *GPIOx_LED, GPIO_TypeDef *GPIOx_SWITCH1, GPIO_TypeDef *GPIOx_SWITCH2, FND_TypeDef *fnd, ULTRA_TypeDef *ultra, BLINK_TypeDef *blink, DHT_TypeDef *dht, TIMER_TypeDef *timerx, uint32_t *temp, uint32_t *temperature, uint32_t *humidity);


void delay(int n);
void DOT3_Timer(uint32_t *DOT3, uint32_t *btn_flag2);
void led_blink_Timer(uint32_t *switch_in, uint32_t *btn, uint32_t *btn_flag, uint32_t *led_left, uint32_t *led_right, uint32_t *led_emer, uint32_t *btn_detect, uint32_t *left_flag, uint32_t *right_flag, uint32_t *emer_flag);

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

void BLINK_init(BLINK_TypeDef *blink, uint32_t duty_rate);
// void PWM_init(BLINK_TypeDef *blink, uint32_t duty_rate);

uint32_t High_Low_Beam(uint32_t *beam_state, uint32_t *beam_detect);

void Timer_stop(TIMER_TypeDef *timerx);
void Timer_start(TIMER_TypeDef *timerx);
void Timer_clear(TIMER_TypeDef *timerx);
void Timer_write_psc(TIMER_TypeDef *timerx, uint32_t psc);
void Timer_write_arr(TIMER_TypeDef *timerx, uint32_t arr);
uint32_t Timer_read(TIMER_TypeDef *timerx);

void blink_led_fnd_func(GPIO_TypeDef *GPIOx_LED, GPIO_TypeDef *GPIOx_SWITCH1, GPIO_TypeDef *GPIOx_SWITCH2, FND_TypeDef *fnd, TIMER_TypeDef *timerx);

void toggle_led_fnd(TIMER_TypeDef *timerx, volatile uint8_t *ggambbak, volatile uint8_t *blink_flag, volatile uint8_t *led_data, volatile uint8_t *fnd_blink);

#define led_default 0b11

int main() {
    LED_init(GPIOC);
    Switch_init(GPIOD);

    FND_init(FND, POWER_ON);
    FND_writeDot(FND, 0);

    Timer_write_psc(TIMER2, (10000000 - 1));
    Timer_write_arr(TIMER2, 5 - 1);
    Timer_start(TIMER2);

    uint32_t DOT3 = (1 << 2);
    uint32_t temp = 0;
    uint32_t temperature = 0;
    uint32_t humidity = 0;

    uint32_t distance = 0;
    uint32_t btn_flag = 0;
    uint32_t sw_flag1 = 0;
    uint32_t sw_flag2 = 0;
    uint32_t btn_flag3 = 0;
    uint32_t btn_detect = 0;
    uint32_t blink_flag = 0;
    uint32_t fnd_blink = 0;
    uint32_t ggambbak = 0;
    uint32_t fnd_shape = 0;
    uint32_t led_data = 0b11;

    while (1) {
        DOT3_Timer(&DOT3, &btn_flag3);

        uint32_t sw = Switch_read(GPIOD);

        switch (sw) {
            case 0x00:
                if (temp == 10000) temp = -1;
                temp++;
                FND_writeData(FND, temp);
                delay(100);
                break;

            case (1 << 7):
                if (temp == 0) temp = 10000;
                temp--;
                FND_writeData(FND, temp);
                delay(100);
                break;

            case (1 << 6):
                Ultra_init(ULTRA, POWER_ON);
                delay(500);
                distance = Ultra_read(ULTRA);
                FND_writeData(FND, distance);
                Ultra_init(ULTRA, POWER_OFF);
                BLINK_init(BLINK, distance);
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

            case (1 << 3): {
                LED_write(GPIOC, led_default);
                FND_init(FND,POWER_OFF);
                while(Switch_read(GPIOD) == (1<<3))
                {
                    if(btn_flag)
                    {
                        ggambbak = 0b11;
                        fnd_shape = BOTH;
                        if(Timer_read(TIMER2) == 0 && blink_flag == 0)
                        {
                            blink_flag = 1;
                            led_data ^= ggambbak;
                            fnd_blink = (led_data & ggambbak) == 0 ? POWER_OFF : POWER_ON;
                        }
                        else if(Timer_read(TIMER2) != 0) blink_flag = 0;

                        delay(10);

                        LED_write(GPIOC, led_data);
                        FND_init(FND,fnd_blink);
                        FND_writeData(FND, fnd_shape);
                    }
                    else if(sw_flag1)
                    {
                        ggambbak = 0b01;
                        fnd_shape = RIGHT;
                        if(Timer_read(TIMER2) == 0 && blink_flag == 0)
                        {
                            blink_flag = 1;
                            led_data ^= ggambbak;
                            fnd_blink = (led_data & ggambbak) == 0 ? POWER_OFF : POWER_ON;
                        }
                        else if(Timer_read(TIMER2) != 0) blink_flag = 0;

                        delay(10);

                        LED_write(GPIOC, led_data);
                        FND_init(FND,fnd_blink);
                        FND_writeData(FND, fnd_shape); // debugging
                    }
                    else if(sw_flag2)
                    {
                        ggambbak = 0b10;
                        fnd_shape = LEFT;
                        if(Timer_read(TIMER2) == 0 && blink_flag == 0)
                        {
                            blink_flag = 1;
                            led_data ^= ggambbak;
                            fnd_blink = (led_data & ggambbak) == 0 ? POWER_OFF : POWER_ON;
                        }
                        else if(Timer_read(TIMER2) != 0) blink_flag = 0;

                        delay(10);

                        LED_write(GPIOC, led_data);
                        FND_init(FND,fnd_blink);
                        FND_writeData(FND, fnd_shape); // debugging
                    }

                    switch(Switch_read(GPIOB))
                    {
                        case (1<<0):
                            sw_flag1 = 1;
                            break;

                        case (1<<1):
                            sw_flag2 = 1;
                            break;

                        case (1<<4):
                            delay(10);
                            if((Switch_read(GPIOB) == (1<<4)) && (btn_detect == 0))
                            {
                                btn_detect = 1;
                                btn_flag ^= 1;
                            }
                            break;

                        default:
                            btn_detect = 0;
                            sw_flag1 = 0;
                            sw_flag2 = 0;
                            if(!btn_flag)
                            {
                                led_data = 0b11;
                                LED_write(GPIOC, led_default);
                                FND_init(FND,POWER_OFF);
                            }
                    }

                }

                LED_write(GPIOC, 0);
                FND_init(FND, POWER_ON);
                break;
            }

            default:
                FND_writeData(FND, 7777);
                break;
        }
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

void FND_init(FND_TypeDef *fnd, uint32_t power){
    fnd->FCR = power;
}

void FND_writeData(FND_TypeDef *fnd, uint32_t data){
    fnd->FDR = data;
}

void FND_writeDot(FND_TypeDef *fnd, uint32_t dot){
    fnd->FPR = dot;
}

void Ultra_init(ULTRA_TypeDef *ultra, uint32_t power){
    ultra->UCR = power;
}

uint32_t Ultra_read(ULTRA_TypeDef *ultra){
    return ultra->UDR;
}

void DHT_init(DHT_TypeDef *dht, uint32_t moder){
    dht->DMR = moder;
}

uint32_t DHT_read(DHT_TypeDef *dht){
    return dht->DDR;
}

void BLINK_init(BLINK_TypeDef *blink, uint32_t duty_rate){
    blink->BDR = duty_rate;
}


void Timer_stop(TIMER_TypeDef *timerx){
    timerx->TCR = 0;
}
void Timer_start(TIMER_TypeDef *timerx){
    timerx->TCR = (1<<0);
}
void Timer_clear(TIMER_TypeDef *timerx){
    timerx->TCR = (1<<1);
}
void Timer_write_psc(TIMER_TypeDef *timerx, uint32_t psc){
    timerx->PSC = psc;
}
void Timer_write_arr(TIMER_TypeDef *timerx, uint32_t arr){
    timerx->ARR = arr;
}
uint32_t Timer_read(TIMER_TypeDef *timerx){
    return timerx->TCNR;
}

void DOT3_Timer(uint32_t *DOT3, uint32_t *btn_flag2){
    if(Timer_read(TIMER2) == 0 && *btn_flag2 == 0){
        *DOT3 ^= (1<<2);
        *btn_flag2 = 1;
    }
    else if(Timer_read(TIMER2)!=0) *btn_flag2 = 0;

    FND_writeDot(FND, *DOT3);
}