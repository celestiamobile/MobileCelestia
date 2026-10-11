#!/bin/sh

export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin:$PATH"

DIDBUILD=0

APP_RESOURCES=$BUILT_PRODUCTS_DIR/$UNLOCALIZED_RESOURCES_FOLDER_PATH
CELESTIA_ROOT=$APP_RESOURCES/CelestiaResources
CELESTIA_REPO_ROOT=`pwd`/../Celestia
CELESTIA_CONTENT_REPO_ROOT=`pwd`/../CelestiaContent
CELESTIA_LOCALIZATION_REPO_ROOT=`pwd`/../CelestiaLocalization

LOCALE_ROOT=$CELESTIA_ROOT/locale

mkdir -p $LOCALE_ROOT

convert_po()
{
    POT=$1/$2.pot
    for po in $1/*.po; do
        f=${po##*/};f=${f%.*}
        LANG_ROOT=$LOCALE_ROOT/$f/LC_MESSAGES
        mkdir -p $LANG_ROOT
        if [ $po -nt $LANG_ROOT/$2.mo ];then
            echo "Create $LANG_ROOT/$2.mo"
            msgmerge --quiet --output-file=$PROJECT_TEMP_DIR/$f.po --lang=$f --sort-output $po $POT
            msgfmt -o $LANG_ROOT/$2.mo $PROJECT_TEMP_DIR/$f.po
            DIDBUILD=1
        fi
    done
}

convert_po "$CELESTIA_REPO_ROOT/po" "celestia"
convert_po "$CELESTIA_CONTENT_REPO_ROOT/po" "celestia-data"
convert_po "$CELESTIA_LOCALIZATION_REPO_ROOT/common" "celestia_ui"

create_lproj()
{
    for po in $1/*.po; do
        f=${po##*/};f=${f%.*}
        mkdir -p $APP_RESOURCES/$f.lproj
    done
}

create_lproj "$CELESTIA_LOCALIZATION_REPO_ROOT/common"

if [ $DIDBUILD -eq 1 ];then
    echo "Touch $BUILT_PRODUCTS_DIR/$PRODUCT_NAME.app"
    touch -c $BUILT_PRODUCTS_DIR/$PRODUCT_NAME.app
fi
