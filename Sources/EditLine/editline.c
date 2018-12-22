#include <stdio.h>
#include <stdlib.h>
#include "include/editline.h"
#include <histedit.h>

static EditLine *editLine;
static History *historyInstance;
static HistEvent historyEvent;

static char *prompt(EditLine *e) {
    return "> ";
}

void lineEditorCreate(void) {
    editLine = el_init("command", stdin, stdout, stderr);
    el_set(editLine, EL_PROMPT, &prompt);
    el_set(editLine, EL_EDITOR, "emacs");

    historyInstance = history_init();
    history(historyInstance, &historyEvent, H_SETSIZE, 800);
    el_set(editLine, EL_HIST, history, historyInstance);
}

void lineEditorDestroy(void) {
    if (historyInstance != NULL) {
        history_end(historyInstance);
        historyInstance = NULL;
    }
    
    if (editLine != NULL) {
        el_reset(editLine);
        el_end(editLine);
        editLine = NULL;
    }
}

const char *lineEditorReadLine(void) {

    int count = 0;

    const char *line = el_gets(editLine, &count);
    
    if (count <= 0) {
        return NULL;
    }
    
    if (line[0] != '\n') {
        history(historyInstance, &historyEvent, H_ENTER, line);
    }
    
    return line;
}

void lineEditorReset(void) {
    el_reset(editLine);
}
