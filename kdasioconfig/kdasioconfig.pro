TEMPLATE = app
TARGET = kdasioconfig

QT += multimedia

HEADERS       = kdasioconfig.h \
    toml.h

SOURCES       = kdasioconfig.cpp \
                main.cpp

FORMS        += kdasioconfigbase.ui

#target.path = $$[QT_INSTALL_EXAMPLES]/multimedia/kdasioconfig
INSTALLS += target

QT+=widgets
#include(../shared/shared.pri)
