
include(klayout.pri)

TEMPLATE = subdirs

SUBDIRS = \
  klayout_main \
  unit_tests \
  tl \
  gsi \
  db \
  rdb \
  lym \
  laybasic \
  lay \
  ant \
  img \
  edt \
  ext \
  lib \
  ut \
  plugins \
  buddies \

equals(HAVE_RUBY, "1") {
  SUBDIRS += rba
  rba.depends += gsi
} else {
  SUBDIRS += rbastub
  rbastub.depends += gsi
}

equals(HAVE_PYTHON, "1") {
  SUBDIRS += pya
  pya.depends += gsi
} else {
  SUBDIRS += pyastub
  pyastub.depends += gsi
}

gsi.depends += tl
db.depends += gsi
rdb.depends += db
laybasic.depends += db rdb
ant.depends += laybasic
img.depends += laybasic
edt.depends += laybasic

lym.depends += tl gsi
equals(HAVE_RUBY, "1") {
  lym.depends += rba
} else {
  lym.depends += rbastub
}
equals(HAVE_PYTHON, "1") {
  lym.depends += pya
} else {
  lym.depends += pyastub
}

lay.depends += laybasic ant img edt lym
lib.depends += db

buddies.depends += db tl gsi ut

equals(HAVE_QTBINDINGS, "1") {
  SUBDIRS += gsiqt
  gsiqt.depends += gsi
  laybasic.depends += gsiqt
  lay.depends += gsiqt
}

ext.depends += lay
ut.depends += lay ext lib

plugins.depends += lay ext lib ut

klayout_main.depends += lay ext lib plugins
unit_tests.depends += ut plugins

RESOURCES += \
    laybasic/layResources.qrc \
    ant/layResources.qrc

