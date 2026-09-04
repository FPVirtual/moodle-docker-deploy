#!/bin/bash

#Uso el nombre completo del fichero tar.gz para evitar ambigüedades con el de versiones anteriores

moosh config-set theme moove

if [[ "${SCHOOL_TYPE}" = "FPD" ]];
    then
        echo "... for FPD..."
        cp /init-scripts/themes/fpdist/moove_settings_1782210003.tar.gz /var/www/html/
        moosh theme-settings-import --targettheme moove moove_settings_1782210003.tar.gz
        # Las siguientes instrucciones se deben a que en la exportación-importación el tema no se comporta correctamente y deben forzarse
        moosh config-set displaymarketingbox 1 theme_moove
        cp -R /init-scripts/themes/fpdist/style /var/www/html/theme/moove
        cp /init-scripts/themes/fpdist/footer.mustache /var/www/html/theme/moove/templates
        cp /init-scripts/themes/fpdist/frontpage.mustache /var/www/html/theme/moove/templates
        cp /init-scripts/themes/fpdist/pix/favicon.ico /var/www/html/theme/moove/pix/favicon.ico

        cp /init-scripts/themes/fpdist/politica-privacidad.php /var/www/html/politica-privacidad.php

        moosh config-set frontpage none

        mkdir -p /var/www/html/soporte/
        cp -R /init-scripts/themes/fpdist/soporte /var/www/html/soporte
        cp /init-scripts/themes/fpdist/soporte/secret-sample.php /var/www/html/soporte/secret.php

        mkdir -p /var/www/html/faqs/
        cp -R /init-scripts/themes/fpdist/faqs /var/www/html/faqs

        #Añadido desde madeby para moodle4
        moosh config-set scss "$(cat /init-scripts/themes/fpdist/scss/moove.scss)" theme_moove
    else
        cp /init-scripts/themes/moove_settings_1782210003.tar.gz /var/www/html/
        moosh theme-settings-import --targettheme moove moove_settings_1782210003.tar.gz
        cp /init-scripts/themes/frontpage.mustache /var/www/html/theme/moove/templates
        cp /init-scripts/themes/booFont/* /var/www/html/theme/moove/fonts/
        cp /init-scripts/themes/fpdist/pix/favicon.ico /var/www/html/theme/moove/pix/favicon.ico

        #Quitamos la imagen de fondo de la página de login. Añadido para moodle4.
        moosh config-set loginbgimg '' theme_moove
        moosh config-set brandcolor '#457b9d' theme_moove

        moosh config-set scss "
    input[value|='CC'] {
        display: none !important;
    }

    input[value|='Para'] {
        display: none !important;
    }

    input[value|='Responder Todos'] {
        display: none !important;
    }

    @font-face {
    font-family: 'Boo';
    src: url([[font:theme|Boo.eot]]);
    src: url([[font:theme|Boo.eot]]) format('embedded-opentype'),
    url([[font:theme|Boo.woff]]) format('woff'),
    url([[font:theme|Boo.woff2]]) format('woff2'),
    url([[font:theme|Boo.ttf]]) format('truetype'),
    url([[font:theme|Boo.svg]]) format('svg');
    font-weight: normal;
    font-style: normal;
    }
    .madeby {
        display: none;
    }
    .contact {
        display: none;
    }
    .socialnetworks {
        display: none;
    }
    .supportemail {
        display: none;
    }
    .path-login {
        #page {
            max-width: 100%;
        }
        .login-container {
            .login-logo {
            justify-content: center;
            }
        }
        .login-identityprovider-btn.facebook {
            background-color: $facebook-color;
            color: #fff;
        }
    }
    " theme_moove
fi

echo >&2 "Theme configured."
