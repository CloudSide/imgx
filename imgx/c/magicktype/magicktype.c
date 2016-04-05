//
//  magicktype.c
//  magicktype
//
//  Created by Littlebox222 on 15/1/21.
//  Copyright (c) 2015年 Littlebox222. All rights reserved.
//

#include "magicktype.h"

#include <string.h>
#include <math.h>
#include <ft2build.h>
#include FT_FREETYPE_H
#include <freetype/ftglyph.h>


int convert_unicode(char *str, int *code)
{
    
    int c;
    char *p = str;
    
    *code = *p;
    
    if ((*p & 0x80) == 0x00) {
        *code &= 0x7f;
        if (*code >= 0x0) return 1;
        return -1;
    }
    
    c = (p[1] ^ 0x80) & 0xff;
    *code = (*code << 6) | c;
    if ((c & 0xc0) != 0) return -1;
    
    if ((*p & 0xe0) == 0xc0) {
        *code &= 0x7ff;
        if (*code >= 0x0000080) return 2;
        return -1;
    }
    
    c = (p[2] ^ 0x80) & 0xff;
    *code = (*code << 6) | c;
    if ((c & 0xc0) != 0) return -1;
    
    if ((*p & 0xf0) == 0xe0) {
        *code &= 0xffff;
        if (*code >= 0x0000800) return 3;
        return -1;
    }
    
    c = (p[3] ^ 0x80) & 0xff;
    *code = (*code << 6) | c;
    if ((c & 0xc0) != 0) return -1;
    
    if ((*p & 0xf8) == 0xf0) {
        *code &= 0x1fffff;
        if (*code >= 0x0010000) return 4;
        return -1;
    }
    
    c = (p[4] ^ 0x80) & 0xff;
    *code = (*code << 6) | c;
    if ((c & 0xc0) != 0) return -1;
    
    if ((*p & 0xfc) == 0xf8) {
        *code &= 0x3fffff;
        if (*code >= 0x0200000) return 5;
        return -1;
    }
    
    c = (p[5] ^ 0x80) & 0xff;
    *code = (*code << 6) | c;
    if ((c & 0xc0) != 0) return -1;
    
    if ((*p & 0xfe) == 0xfc) {
        if (*code >= 0x4000000) return 6;
        return -1;
    }
    
    return -1;
}


MT_Font_Color *new_font_color(unsigned char r, unsigned char g, unsigned char b, unsigned char a) {
    MT_Font_Color *font_color = (MT_Font_Color *)malloc(sizeof(MT_Font_Color));
    
    if (font_color == NULL) {
        return NULL;
    }
    
    font_color->r = r;
    font_color->g = g;
    font_color->b = b;
    font_color->a = a;
    return font_color;
}

void destroy_font_color(MT_Font_Color *font_color) {
    if (font_color != NULL) {
        free(font_color);
    }
}

MT_Font *new_font() {
    MT_Font *font = (MT_Font *)malloc(sizeof(MT_Font));
    
    if (font == NULL) {
        return NULL;
    }
    
    font->font_size = 14;
    font->text_kerning = 1;
    font->line_spacing = 1;
    font->font_lean = 0;
    font->word_spacing = 1;
    MT_Font_Color *color = new_font_color(0,0,0,0);
    font->font_color = color;
    font->font_style = MT_font_style_normal;
    font->font_file_index = 0;
    return font;
}

void destroy_font(MT_Font *font) {
    if (font != NULL) {
        if (font->font_color) {
            destroy_font_color(font->font_color);
        }
        free(font);
    }
}

MT_Image *new_image() {
    MT_Image *image = (MT_Image *)malloc(sizeof(MT_Image));
    if (image == NULL) {
        return NULL;
    }
    image->im_w = 0;
    image->im_h = 0;
    image->image_data = NULL;
    return image;
}

void destroy_image(MT_Image *image) {
    if (image != NULL) {
        if (image->image_data != NULL) {
            free(image->image_data);
        }
        free(image);
    }
}

void draw_bitmap(FT_Bitmap* bitmap, unsigned char *image, FT_Int x, FT_Int y, int im_w, int im_h, MT_Font_Color color, int channels) {
    
    FT_Int  i, j, p, q;
    FT_Int  x_max = x + bitmap->width;
    FT_Int  y_max = y + bitmap->rows;
    
    for (i=x, p=0; i<x_max; i++, p++) {
        for (j=y, q=0; j<y_max; j++, q++) {
            
            if (i<0 || j<0 || i>=im_w || j>=im_h) {
                continue;
            }else {
                
                if (channels == 1) {
                    image[j*im_w + i] |= bitmap->buffer[q * bitmap->width + p];
                }else {
                    image[j*im_w*4 + i*4 + 3] |= bitmap->buffer[q * bitmap->width + p];
                }
            }
        }
    }
    
}

void show_image(unsigned char * image, int w, int h)
{
    int i, j;
    
    for (i=0; i<h; i++) {
        for (j=0; j<w; j++) {
            putchar( image[i*w+j] == 0 ? '.' : image[i*w+j] < 128 ? '+' : '*' );
        }
        putchar( '\n' );
    }
}

void unpack_font(const char *font_name, void *lua_function(char *family_name, char *style_name, int index)) {

    FT_Library      library = NULL;
    FT_Face         face = NULL;
    FT_Error        err;
    
    err = FT_Init_FreeType( &library);

    if (err != 0) {
		if (library != NULL)  FT_Done_FreeType(library);
        	return;
    }
    
    err = FT_New_Face(library, font_name, 0, &face);
	
    if (err != 0) {
		if (face != NULL) FT_Done_Face(face);
        	return;
    }
    
    int face_num = (int)face->num_faces;
    FT_Done_Face(face);
    
    int i;
    for (i=0; i<face_num; i++) {
        
        err = FT_New_Face(library, font_name, i, &face);
        
        if (err != 0) {
            if (face != NULL) FT_Done_Face(face);
            continue;
        }
        
        lua_function(face->family_name, face->style_name, i);
        FT_Done_Face(face);
    }
    
    FT_Done_FreeType(library);
}

MT_Image *str_to_image(char *str, int im_w, int im_h, const char *font_name, MT_Font font, int resolution, int channels, int *err) {
	
	*err = 0;    

    if (str == NULL || font_name == NULL) {
		*err = -1;
        	return NULL;
    }
    
    if (channels != 1 && channels != 4) {
        channels = 1;
    }
    
    int mode_all_all = 0;
    int mode_w_h = 0;
    int mode_all_h = 0;
    int mode_w_all = 0;
    
    if (im_w <= 0 && im_h <= 0) {
        mode_all_all = 1;
    }else if (im_w <= 0 && im_h > 0) {
        mode_all_h = 1;
    }else if (im_w > 0 && im_h <= 0) {
        mode_w_all = 1;
    }else {
        mode_w_h = 1;
    }
    
    FT_Library    library;
    FT_Face       face;
    FT_GlyphSlot  slot;
    FT_Matrix     matrix;
    FT_Vector     pen;
    FT_Error      error;
    
    
    const char *filename = font_name;
    char *text = str;
    long num_chars = strlen(text);
    int text_size = font.font_size;
    float text_lean = font.font_lean >= 0 ? font.font_lean : abs(font.font_lean);
    float text_kerning = font.text_kerning;
    float word_spacing = font.word_spacing;
    float line_spacing = font.line_spacing;
    MT_Image *mt_image = (MT_Image *)malloc(sizeof(MT_Image));
    
    if (mt_image == NULL) {
        *err = -1;
        return NULL;
    }
    
    
    error = FT_Init_FreeType( &library );
    if (error != 0) {
        if (library != NULL) FT_Done_FreeType(library);
        *err = error;
        return mt_image;
    }
    
    error = FT_New_Face(library, filename, font.font_file_index, &face);
    if (error != 0) {
        if (library != NULL) FT_Done_FreeType(library);
        if (face != NULL) FT_Done_Face(face);
        *err = error;
        return mt_image;
    }
    
    error = FT_Set_Char_Size(face, text_size * 64, 0, resolution, resolution);
    if (error != 0) {
        if (library != NULL) FT_Done_FreeType(library);
        if (face != NULL) FT_Done_Face(face);
        *err = error;
        return mt_image;
    }
    
    
    slot = face->glyph;
    
    // 计算要写的字数
    int num_text = 0;
    int k;
    int step = 0;
    for (k = 0; k < num_chars; k+=step ) {
        int a = 0;
        step = convert_unicode(text+k, &a);
        
        if (step == -1) {
            break;
        }
        num_text++;
    }
    
    // 计算每个字的宽度
    int *text_width = (int *)malloc(num_text*sizeof(int));
    
    step = 0;
    
    matrix.xx = 0x10000L;
    matrix.xy = text_lean * 0x10000L;
    matrix.yx = 0;
    matrix.yy = 0x10000L;
    pen.x = 0 * 64;
    pen.y = 0;
    
    int index = 0;
    for (k = 0; k < num_chars; k+=step ) {
        
        FT_Set_Transform( face, &matrix, &pen );
        FT_Select_Charmap(face, FT_ENCODING_UNICODE);
        
        int a = 0;
        step = convert_unicode(text+k, &a);
        
        if (step == -1) {
            break;
        }
        
        error = FT_Load_Char(face, a, FT_LOAD_RENDER);
        
        if (a == 10) {
            text_width[index] = 0;
        }else if (a == 13) {
            text_width[index] = -1;
        }else if (a == 9) {
            text_width[index] = text_size * 2 * 64;
        }else if (a == 32) {
            text_width[index] = text_size * 0.5 * 64 + word_spacing * 64;
        }else {
            text_width[index] = slot->advance.x;
        }
        
        index++;
    }
    
    // 计算图像宽高
    int *text_return = (int *)malloc(num_text*sizeof(int));
    int tr;
    for (tr = 0; tr<num_text; tr++) {
        text_return[tr] = -1;
    }
    
    
    matrix.xx = 0x10000L;
    matrix.xy = text_lean * 0x10000L;
    matrix.yx = 0;
    matrix.yy = 0x10000L;
    
    pen.x = 0 * 64;
    pen.y = 0;
    
    step = 0;
    long tmp_w = 0;
    long tmp_h = 0;
    int n;
    int line_num = 1;
    
    if (mode_all_all || mode_all_h) {
        
        long raw_w = 0;
        long raw_h = 0;
        for (n = 0; n<num_text; n++) {
            
            if (text_width[n] != 0) {
                if (text_width[n] == -1) {
                }else {
                    raw_w += text_width[n] + text_kerning * 64;
                }
                
            }else {
                text_return[n] = 1;
                line_num++;
                tmp_w = raw_w > tmp_w ? raw_w : tmp_w;
                raw_w = 0;
            }
        }
        
        im_w = raw_w > tmp_w ? raw_w : tmp_w;
        im_w -= text_kerning * 64;
        im_w /= 64;
        im_h = line_num * (text_size + line_spacing)  - line_spacing + text_size * 0.15;
        
    }else if (mode_w_all || mode_w_h) {

        long raw_w = 0;
        for (n=0; n<num_text; n++) {
            
            if (text_width[n] != 0) {
                
                if (text_width[n] == -1) {
                }else {
                    raw_w += text_width[n] + text_kerning * 64;
                    if (n > 0 && raw_w - text_kerning * 64 >= im_w * 64) {
                        text_return[n] = 1;
                        line_num++;
                        raw_w = text_width[n] + text_kerning * 64;
                    }
                }
            }else {
                text_return[n] = 1;
                line_num++;
                raw_w = 0;
            }
            
            //printf("~~~ n(%d): %d    %ld    raw_w:%ld\n", n, text_return[n], text_width[n], raw_w);
        }
        
        if (mode_w_h) {

        }else {
            im_h = line_num * (text_size + line_spacing)  - line_spacing + text_size * 0.15;
        }
        
    }
    
    // 开始写字
    mt_image->im_w = im_w;
    mt_image->im_h = im_h;
    
    unsigned char *image = (unsigned char *)malloc(im_w * im_h * channels *sizeof(unsigned char));
    
    if (image == NULL) {
        *err = -1;
        return mt_image;
    }
    
    if (channels == 1) {
        memset(image, 0, im_w * im_h);
    }else {
        int i,j;
        for (i=0; i<im_h; i++) {
            for (j=0; j<im_w; j++) {
                image[i*im_w*4 + j*4 + 0] = font.font_color->b;
                image[i*im_w*4 + j*4 + 1] = font.font_color->g;
                image[i*im_w*4 + j*4 + 2] = font.font_color->r;
                image[i*im_w*4 + j*4 + 3] = 0;
            }
        }
    }
    
    matrix.xx = 0x10000L;
    matrix.xy = text_lean * 0x10000L;
    matrix.yx = 0;
    matrix.yy = 0x10000L;
    
    
    pen.x = 0 * 64;
    int target_height = im_h;
    pen.y = (target_height-text_size) * 64;
    
    step = 0;
    int k_text = 0;
    for (n = 0; n < num_chars; n+=step ) {
        
        FT_Set_Transform( face, &matrix, &pen );
        FT_Select_Charmap(face, FT_ENCODING_UNICODE);
        
        int a = 0;
        step = convert_unicode(text+n, &a);
        
        if (step == -1) {
            break;
        }
        
        if (text_return[k_text] == 1) {
            pen.x = 0;
            pen.y -= (text_size + line_spacing) * 64;
            n -= step;
            text_return[k_text] = -1;
            continue;
        }
        
        if (text_width[k_text] == 0) {
            k_text++;
            continue;
        }
        
        if (text_width[k_text] == -1) {
            k_text++;
            continue;
        }
        
        if (text_width[k_text] == text_size * 2 * 64) {
            pen.x += text_width[k_text] + text_kerning * 64;
            k_text++;
            continue;
        }
        
        error = FT_Load_Char(face, a, FT_LOAD_RENDER);
        draw_bitmap(&slot->bitmap, image, slot->bitmap_left, target_height - slot->bitmap_top, im_w, im_h, *font.font_color, channels);
        
        pen.x += text_width[k_text] + text_kerning * 64;
        
        k_text++;
    }
    
    free(text_width);
    free(text_return);
    
    FT_Done_Face    ( face );
    FT_Done_FreeType( library );
    
    mt_image->image_data = image;
    return mt_image;
}
