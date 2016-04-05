//
//  magicktype.h
//  magicktype
//
//  Created by Littlebox222 on 15/1/21.
//  Copyright (c) 2015年 Littlebox222. All rights reserved.
//

#ifndef __magicktype__magicktype__
#define __magicktype__magicktype__

#include <stdio.h>

typedef enum {
    MT_font_style_bold = 0,
    MT_font_style_italic = 1,
    MT_font_style_normal = 2,
    MT_font_style_light = 3
} MT_Font_Style;


typedef struct  MT_Font_Color_ {
    unsigned char r;
    unsigned char g;
    unsigned char b;
    unsigned char a;
} MT_Font_Color;


typedef struct  MT_Font_ {
    int font_size;
    float text_kerning;
    float word_spacing;
    float line_spacing;
    float font_lean;
    MT_Font_Color *font_color;
    MT_Font_Style font_style;
    int font_file_index;
} MT_Font;


typedef struct  MT_Image_ {
    int im_w;
    int im_h;
    unsigned char *image_data;
} MT_Image;

MT_Font_Color *new_font_color(unsigned char r, unsigned char g, unsigned char b, unsigned char a);
void destroy_font_color(MT_Font_Color *font_color);

MT_Font *new_font();
void destroy_font(MT_Font *font);

MT_Image *new_image();
void destroy_image(MT_Image *image);

int convert_unicode(char *str, int *code);

MT_Image *str_to_image(char *str, int im_w, int im_h, const char *font_name, MT_Font font, int resolution, int channels, int *err);

void unpack_font(const char *font_name, void *lua_function(char *family_name, char *style_name, int index));

#endif /* defined(__magicktype__magicktype__) */
