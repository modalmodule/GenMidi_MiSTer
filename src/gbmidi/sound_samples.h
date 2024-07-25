#ifndef SOUND_SAMPLES_H
#define SOUND_SAMPLES_H
#define const_sound_sample_max 32
extern unsigned long sound_sample_address[const_sound_sample_max];
extern unsigned long sound_sample_length[const_sound_sample_max];
#define const_sound_sample_used 4
#define const_sound_player_explode 0
#define const_sound_pickup_collect 1
#define const_sound_alarm 2
#define const_sound_newtype 3
#endif
