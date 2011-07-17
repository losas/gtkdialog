%{
/*
 * gtkdialog_parser.y: A simple grammar for the XML-like language we use.
 * Gtkdialog - A small utility for fast and easy GUI building.
 * Copyright (C) 2003-2007  László Pere <pipas@linux.pte.hu>
 * Copyright (C) 2011  Thunor <thunorsif@hotmail.com>
 * 
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License along
 * with this program; if not, write to the Free Software Foundation, Inc.,
 * 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
 */

/*
**
** $Id: parser.y,v 1.5 2004/11/25 21:16:57 root Exp root $
** $Log: parser.y,v $
** Revision 1.5  2004/11/25 21:16:57  root
** *** empty log message ***
**
** Revision 1.4  2004/11/25 21:15:21  root
**   o No, the grammar still has problems.
**
** Revision 1.2  2004/11/25 19:53:03  pipas
**   o New object: tag attributes.
**
** Revision 1.1  2004/11/19 22:10:08  pipas
** Initial revision
**
*/

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <gtk/gtk.h>

#include "gtkdialog.h"
#include "config.h"
#include "automaton.h"
#include "attributes.h"
#include "gtkdialog_parser.h"

int linenumber = 1;
extern gchar *Token;
extern gboolean option_no_warning;
extern gboolean option_print_ir;

//
// Function declarations
//
int yywarning(char *c);
void yyerror_simple(char *c);

static inline void
start_up(void) 
{
	if (!option_print_ir) {
		run_program();
		return;
	} else {
		print_program();
		exit(EXIT_SUCCESS);
	}
}

%}

%union { 
  double     dval;
  char      *cval;
  GList     *lval;
  tag_attr *nvval;
  gint       ival;
};

%token         WINDOW PART_WINDOW EWINDOW
%token         VBOX PART_VBOX EVBOX
%token         HBOX PART_HBOX EHBOX
%token         NOTEBOOK ENOTEBOOK PART_NOTEBOOK
%token <cval>  FRAME
%token <cval>  TAG_ATTR_NAME
%type  <nvval> tagattr
%token         EFRAME
%token         ENTRY EENTRY PART_ENTRY
%token         MENUBAR EMENUBAR MENU EMENU 
%token         MENUITEM PART_MENUITEM EMENUITEM
%token         MENUITEMSEPARATOR EMENUITEMSEPARATOR
%token         EDIT PART_EDIT EEDIT
%token         TREE PART_TREE ETREE
%token         CHOOSER PART_CHOOSER ECHOOSER
%token         LABEL ELABEL
%token         ITEM EITEM PART_ITEM
%token         BUTTON PART_BUTTON EBUTTON 
%token         BUTTONOK BUTTONCANCEL BUTTONHELP BUTTONYES BUTTONNO
%token         CHECKBOX ECHECKBOX PART_CHECKBOX
%token         RADIO ERADIO PART_RADIO
%token         PROGRESS EPROGRESS PART_PROGRESS
%token         LIST PART_LIST ELIST
%token         TABLE ETABLE
%token         COMBO PART_COMBO ECOMBO
%token         GVIM EGVIM
%token         TEXT PART_TEXT ETEXT
%token         PIXMAP PART_PIXMAP EPIXMAP 
%token         DEFAULT EDEFAULT
%token         VISIBLE EVISIBLE
%token         VARIABLE EVARIABLE
%token         WIDTH EWIDTH
%token         HEIGHT EHEIGHT
%token         INPUT INPUTFILE EINPUT PART_INPUT PART_INPUTFILE
%token         OUTPUT OUTPUTFILE EOUTPUT

%token         ACTION EACTION PART_ACTION 

%token         COMM ENDCOMM
%token         IF ENDIF 
%type  <ival>  then endif
%token         WHILE EWHILE
%type  <ival>  while do ewhile
%token         SHOW_WIDGETS
%token <cval>  EMB_VARIABLE EMB_NUMBER
%token         END_OF_FILE
%token <dval>  NUMBER 
%token <cval>  STRING

%left '='
%left '-' '+'        
%left '*' '/'

%nonassoc      UMINUS 

	/**************************************************************
	 * Thunor: Newly supported widgets.
	 **************************************************************/
%token         HSEPARATOR PART_HSEPARATOR EHSEPARATOR
%token         VSEPARATOR PART_VSEPARATOR EVSEPARATOR
%token         COMBOBOXTEXT PART_COMBOBOXTEXT ECOMBOBOXTEXT
%token         COMBOBOXENTRY PART_COMBOBOXENTRY ECOMBOBOXENTRY
%token         HSCALE PART_HSCALE EHSCALE
%token         VSCALE PART_VSCALE EVSCALE

%% 
window
  : attr wlist { 
    		token_store(PUSH | WIDGET_WINDOW); 
		start_up();
	}
  | WINDOW wlist attr EWINDOW { 
    		token_store(PUSH | WIDGET_WINDOW); 
		start_up();
	}
  | PART_WINDOW tagattr '>' wlist attr EWINDOW { 
    		token_store_attr(PUSH | WIDGET_WINDOW, $2); 
		start_up();
	}
  ;

wlist
  : widget
  | wlist widget       { 
		token_store(SUM);      
	}
  | imperative
  | wlist imperative
  | VBOX wlist EVBOX   { 
		token_store(PUSH | WIDGET_VBOX); 
	}
  | wlist VBOX wlist EVBOX   { 
		token_store(PUSH | WIDGET_VBOX); 
		token_store(SUM);      
	}
  | PART_VBOX tagattr '>' wlist EVBOX {
		token_store_attr(PUSH | WIDGET_VBOX, $2); 
	}
  | wlist PART_VBOX tagattr '>' wlist EVBOX {
		token_store_attr(PUSH | WIDGET_VBOX, $3); 
		token_store(SUM);      
	}
  | HBOX wlist EHBOX   { 
		token_store(PUSH | WIDGET_HBOX); 
	}
  | wlist HBOX wlist EHBOX   { 
		token_store(PUSH | WIDGET_HBOX); 
		token_store(SUM);      
	}
  | PART_HBOX tagattr '>' wlist EHBOX {
		token_store_attr(PUSH | WIDGET_HBOX, $2); 
	}
  | wlist PART_HBOX tagattr '>' wlist EHBOX {
		token_store_attr(PUSH | WIDGET_HBOX, $3); 
		token_store(SUM);      
	}
  | NOTEBOOK wlist ENOTEBOOK   { 
		token_store(PUSH | WIDGET_NOTEBOOK); 
	}
  | wlist NOTEBOOK wlist ENOTEBOOK   { 
		token_store(PUSH | WIDGET_NOTEBOOK); 
		token_store(SUM);      
	}
  | PART_NOTEBOOK tagattr '>' wlist ENOTEBOOK {
		token_store_attr(PUSH | WIDGET_NOTEBOOK, $2);
	}
  | wlist PART_NOTEBOOK tagattr '>' wlist ENOTEBOOK {
		token_store_attr(PUSH | WIDGET_NOTEBOOK, $3);
		token_store(SUM);      
	}
  | FRAME wlist EFRAME { 
		token_store_with_argument(SET|ATTR_LABEL, $1); 
		token_store(PUSH | WIDGET_FRAME); 
	}
  | wlist FRAME wlist EFRAME { 
		token_store_with_argument(SET|ATTR_LABEL, $2); 
		token_store(PUSH | WIDGET_FRAME); 
		token_store(SUM);      
	}
  ;

widget
  :  text
  | entry
  | edit
  | tree
  | chooser
  | button
  | checkbox
  | radiobutton
  | progressbar
  | list
  | table
  | combo
  | pixmap
  | gvim
  | menubar
  | hseparator
  | vseparator
  | comboboxtext
  | comboboxentry
  | hscale
  | vscale
  ;

entry
  : ENTRY attr EENTRY {
                          token_store(PUSH | WIDGET_ENTRY); 
			 }
  | PART_ENTRY tagattr '>' attr EENTRY {
                token_store_attr(PUSH | WIDGET_ENTRY, $2);
	}
  | ENTRY attr ENTRY {
                  yyerror("</entry> expected instead of <entry>.");} 
  ;

edit
  : EDIT attr EEDIT  {
    		token_store(PUSH | WIDGET_EDIT); 
	}
  | PART_EDIT tagattr '>' attr EEDIT {
    		token_store_attr(PUSH | WIDGET_EDIT, $2); 
    	}
  | EDIT attr EDIT   {
    		yyerror("</edit> expected instead of <edit>.");
	}
  ;

tree
  : TREE attr ETREE  {
		token_store(PUSH | WIDGET_TREE); 
	}
  | PART_TREE tagattr '>' attr ETREE {
    		token_store_attr(PUSH | WIDGET_TREE, $2); 
	}
  | TREE attr TREE {
   		yyerror("</tree> expected instead of <tree>.");
	}
  ;

chooser
  : CHOOSER attr ECHOOSER  {
		token_store(PUSH | WIDGET_CHOOSER); 
	}
  | PART_CHOOSER tagattr '>' attr ECHOOSER {
		token_store_attr(PUSH | WIDGET_CHOOSER, $2); 
	}
  | CHOOSER attr CHOOSER {
		yyerror("</chooser> expected instead of <chooser>.");
	}
  ;

text
  : TEXT attr ETEXT {
		token_store(PUSH | WIDGET_LABEL); 
	} 
  | PART_TEXT tagattr '>' attr ETEXT {
                token_store_attr(PUSH | WIDGET_LABEL, $2);
	}
  | TEXT attr TEXT  {yyerror("</text> expected instead of <text>.");}
  ;

button
  : BUTTON attr EBUTTON       {token_store(PUSH | WIDGET_BUTTON);  }
  | PART_BUTTON tagattr '>' attr EBUTTON {
                token_store_attr(PUSH | WIDGET_BUTTON, $2);
	}
  | BUTTONOK attr EBUTTON     {token_store(PUSH | WIDGET_OKBUTTON);}
  | BUTTONCANCEL attr EBUTTON {token_store(PUSH | WIDGET_CANCELBUTTON);}
  | BUTTONHELP attr EBUTTON   {token_store(PUSH | WIDGET_HELPBUTTON);}
  | BUTTONNO attr EBUTTON     {token_store(PUSH | WIDGET_NOBUTTON);}
  | BUTTONYES attr EBUTTON    {token_store(PUSH | WIDGET_YESBUTTON);}
  ;

checkbox
  : CHECKBOX attr ECHECKBOX {
		token_store(PUSH | WIDGET_CHECKBOX);
	}
  | PART_CHECKBOX tagattr '>' attr ECHECKBOX {
		//token_store_with_tag_attributes(PUSH | WIDGET_CHECKBOX, $2);
                token_store_attr(PUSH | WIDGET_CHECKBOX, $2);
	}
  | CHECKBOX attr CHECKBOX  {
		yyerror("</checkbox> expected instead of <checkbox>.");
	}
  ;

radiobutton
  : RADIO attr ERADIO    {
	   	token_store(PUSH | WIDGET_RADIO);
           }
  | PART_RADIO tagattr '>' attr ERADIO {
                token_store_attr(PUSH | WIDGET_RADIO, $2);
	   }
  | RADIO attr RADIO  {
		yyerror("</radiobutton> expected instead of <radiobutton>.");
           }
  ;

progressbar
  : PROGRESS attr EPROGRESS {
	   	token_store(PUSH | WIDGET_PROGRESS);
           }
  | PART_PROGRESS tagattr '>' attr EPROGRESS {
                token_store_attr(PUSH | WIDGET_PROGRESS, $2);
	   }
  | PROGRESS attr PROGRESS  {
		yyerror("</progressbar> expected instead of <progressbar>.");
           }
  ;

list
  : LIST attr ELIST {
		token_store(PUSH | WIDGET_LIST); 
	}
  | PART_LIST tagattr '>' attr ELIST {
		token_store_attr(PUSH | WIDGET_LIST, $2); 
    	}
  | LIST attr LIST   {
    		yyerror("</list> expected instead of <list>.");
	}
  ;

table
  : TABLE attr ETABLE          {token_store(PUSH | WIDGET_TABLE);}
  ;

combo
  : COMBO attr ECOMBO                  {
    		token_store(PUSH | WIDGET_COMBO);
	}
  | PART_COMBO tagattr '>' attr ECOMBO {
    		token_store_attr(PUSH | WIDGET_COMBO, $2);
	}                                 
  ;

gvim
  : GVIM attr EGVIM             {token_store(PUSH | WIDGET_GVIM);}
  ;

pixmap
  : PIXMAP attr EPIXMAP       {token_store(PUSH | WIDGET_PIXMAP);}
  | PART_PIXMAP tagattr '>' attr EPIXMAP {
    		token_store_attr(PUSH | WIDGET_PIXMAP, $2);
	}
  ;

menubar
  : MENUBAR EMENUBAR        {
                    yyerror("Empty menubar without a single <menu> tag.");
		    }
  | MENUBAR menus EMENUBAR  {token_store(PUSH | WIDGET_MENUBAR);}
  ;

menus
  : MENU EMENU                { yyerror("Empty menu without <menuitem> tag.");}
  | MENU menuitems attr EMENU      { token_store(PUSH | WIDGET_MENU);   } 
  | menus MENU EMENU          { yyerror("Empty menu without <menuitem> tag.");}
  | menus MENU menuitems attr EMENU { 
		token_store(PUSH | WIDGET_MENU);   
		token_store(SUM); 
	} 
  ;

menuitems
  : MENUITEM attr EMENUITEM {
		token_store(PUSH | WIDGET_MENUITEM); 
	} 
  | PART_MENUITEM tagattr '>' attr EMENUITEM {
    		token_store_attr(PUSH | WIDGET_MENUITEM, $2); 
    	}
  | menuitems MENUITEM attr EMENUITEM { 
		token_store(PUSH | WIDGET_MENUITEM); 
		token_store(SUM);
	} 
  | menuitems PART_MENUITEM tagattr '>' attr EMENUITEM {
    		token_store_attr(PUSH | WIDGET_MENUITEM, $3); 
		token_store(SUM);
    	}
  | menuitems MENUITEMSEPARATOR EMENUITEMSEPARATOR {
		token_store(PUSH | WIDGET_MENUITEMSEPARATOR);
		token_store(SUM);
	}
  ;

	/**************************************************************
	 * Thunor: Newly supported widgets.
	 * Don't forget to add them to the widget list above and
	 * to create a token for them towards the top of this file.
	 * The WIDGET_*s are defined in automaton.h.
	 **************************************************************/
hseparator
  : HSEPARATOR EHSEPARATOR {
		token_store(PUSH | WIDGET_HSEPARATOR);
	}
  | PART_HSEPARATOR tagattr '>' EHSEPARATOR {
		token_store_attr(PUSH | WIDGET_HSEPARATOR, $2);
	}
  ;

vseparator
  : VSEPARATOR EVSEPARATOR {
		token_store(PUSH | WIDGET_VSEPARATOR);
	}
  | PART_VSEPARATOR tagattr '>' EVSEPARATOR {
		token_store_attr(PUSH | WIDGET_VSEPARATOR, $2);
	}
  ;

comboboxtext
  : COMBOBOXTEXT attr ECOMBOBOXTEXT {
		token_store(PUSH | WIDGET_COMBOBOXTEXT);
	}
  | PART_COMBOBOXTEXT tagattr '>' attr ECOMBOBOXTEXT {
		token_store_attr(PUSH | WIDGET_COMBOBOXTEXT, $2);
	}
  ;

comboboxentry
  : COMBOBOXENTRY attr ECOMBOBOXENTRY {
		token_store(PUSH | WIDGET_COMBOBOXENTRY);
	}
  | PART_COMBOBOXENTRY tagattr '>' attr ECOMBOBOXENTRY {
		token_store_attr(PUSH | WIDGET_COMBOBOXENTRY, $2);
	}
  ;

hscale
  : HSCALE attr EHSCALE {
		token_store(PUSH | WIDGET_HSCALE);
	}
  | PART_HSCALE tagattr '>' attr EHSCALE {
		token_store_attr(PUSH | WIDGET_HSCALE, $2);
	}
  ;

vscale
  : VSCALE attr EVSCALE {
		token_store(PUSH | WIDGET_VSCALE);
	}
  | PART_VSCALE tagattr '>' attr EVSCALE {
		token_store_attr(PUSH | WIDGET_VSCALE, $2);
	}
  ;

attr
  :
  | attr defaultvalue
  | attr visible
  | attr variable
  | attr label
  | attr width
  | attr height
  | attr input
  | attr output
  | attr action
  | attr item
  ;

label
  :    LABEL STRING ELABEL          {
		token_store_with_argument( SET | ATTR_LABEL, $2);     }
  ;

variable
  : VARIABLE STRING EVARIABLE    {
     token_store_with_argument( SET | ATTR_VARIABLE, $2); }
  ; 

visible
  : VISIBLE STRING EVISIBLE       {
     token_store_with_argument( SET | ATTR_VISIBLE, $2);  }
  ; 

defaultvalue
  : DEFAULT STRING EDEFAULT  {
     token_store_with_argument( SET | ATTR_DEFAULT, $2);   }
  ;

width
  : WIDTH STRING EWIDTH             {
     token_store_with_argument( SET | ATTR_WIDTH, $2);    }
  ;

height
  : HEIGHT STRING EHEIGHT           {
     token_store_with_argument( SET | ATTR_HEIGHT, $2);   }
  ;

input
  : INPUT STRING EINPUT    { 
		token_store_with_argument(SET|ATTR_INPUT|SUB_ATTR_SHELL,$2);
	}
  | PART_INPUT tagattr '>' STRING EINPUT {
		token_store_with_argument_attr(SET|ATTR_INPUT, $4, $2); 
	}
  | INPUTFILE STRING EINPUT  { 
		token_store_with_argument(SET|ATTR_INPUT|SUB_ATTR_FILE,$2); 
	}
  | PART_INPUTFILE tagattr '>' STRING EINPUT {
		token_store_with_argument_attr(SET|ATTR_INPUT|SUB_ATTR_FILE, $4, $2); 
	}
  | PART_INPUTFILE tagattr '>' EINPUT {
		token_store_with_argument_attr(SET|ATTR_INPUT|SUB_ATTR_FILE, "", $2); 
	}
  ;

output
  : OUTPUT STRING EOUTPUT {
	         fprintf( stderr, "<output>: Not implemented.\n" ); 
	}
  | OUTPUTFILE STRING EOUTPUT {
         	token_store_with_argument(SET|ATTR_OUTPUT|SUB_ATTR_FILE,$2);
	}
  ;

action
  : ACTION STRING EACTION  { 
		token_store_with_argument( SET|ATTR_ACTION, $2); 
	}
  | PART_ACTION tagattr '>' STRING EACTION {
		token_store_with_argument_attr(SET | ATTR_ACTION, $4, $2);
	}
  ;


item
  : ITEM STRING EITEM { 
		token_store_with_argument( SET | ATTR_ITEM, $2);
	}
  | ITEM EITEM {
		token_store_with_argument( SET | ATTR_ITEM, "");
    	}
  | PART_ITEM tagattr '>' STRING EITEM {
		      token_store_with_argument_attr(SET | ATTR_ITEM, $4, $2);
                    }
  ;

tagattr
  : TAG_ATTR_NAME '=' STRING {
       		$$ = new_tag_attributeset($1, $3); 
	}
  | tagattr TAG_ATTR_NAME '=' STRING { 
       		$$ = add_tag_attribute($1, $2, $4); 
	}
  ;

imperative
  : COMM assignment '>' ENDCOMM 
  | SHOW_WIDGETS { 
		token_store(SHOW);     
	}
  | if expression '>' then wlist endif {
  		instruction_set_jump($4, $6 + 1);
	}
  | while expression '>' do wlist ewhile {
		instruction_set_jump($4, $6 + 1);
		instruction_set_jump($6 + 1, $1);
	}
  ;

assignment
  : EMB_VARIABLE ':' '=' expression {
		token_store_with_argument(IMASSG | VARIABLE_NAME, $1); 
	}
  ;

expression
  : EMB_VARIABLE {
		token_store_with_argument(IMPUSH | VARIABLE_NAME, $1); 
	}
  | EMB_NUMBER {
		token_store_with_argument(IMPUSH | CONST_NUMBER, $1); 
  	}
  | expression '+' expression {
  		token_store(IMPUSH | OP_ADD);
	}
  | expression '-' expression {
  		token_store(IMPUSH | OP_SUBST);
	}
  | expression '*' expression {
  		token_store(IMPUSH | OP_MULT);
	}
  | expression '/' expression {
  		token_store(IMPUSH | OP_DIV);
	}
  | expression '=' expression {
  		token_store(IMPUSH | REL_EQ);
	}
  | expression '!' '=' expression {
  		token_store(IMPUSH | REL_NE);
	}
  ;


if: IF 
  ;

then
  :     { 
		token_store(IFNGOTO); 
		$$ = instruction_get_pc();
	}
  ;

endif
  : ENDIF  { $$ = instruction_get_pc(); }
  ;

while
  : WHILE { $$ = instruction_get_pc(); }
  ;

ewhile
  : EWHILE {
		token_store(GOTO); 
		$$ = instruction_get_pc();
	}
  ;

do
  : { 
		token_store(IFNGOTO); 
		$$ = instruction_get_pc();
    }
  ;

%%

extern gboolean option_print_ir;

int gtkdialog_wrap(void)
{
	#ifdef DEBUG
	g_message("%s(): Start", __func__);
	#endif
	return 1;
}

int gtkdialog_error(char *c)
{
	g_error("%s: Error in line %d, near token '%s': %s\n", 
		PACKAGE, linenumber, Token, c);
}

void yyerror_simple(char *c)
{
	g_error("%s: Error: %s", PACKAGE, c);
}

int yywarning(char *c){
	#ifdef DEBUG
		g_warning("Warning: %s.", c);
	#endif
	if (!option_no_warning)
		g_warning("%s: Warning: %s.", PACKAGE, c);
	return option_no_warning;
}
