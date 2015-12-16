/// <reference path="../typings/requirejs/require.d.ts" />
"use strict";
var defaultLocaleId = "fr-fr", debug = true;
require.config({
    baseUrl: "scripts",
    paths: {
        "angular": "angular.min",
        "angular-locale": "i18n/angular-locale_" + (localStorage.getItem("localeId") || defaultLocaleId),
        "angular-route": "angular-route.min",
        "angular-ui-bootstrap": "angular-ui/ui-bootstrap-tpls.min",
        "moment": "moment-with-locales.min",
        "dui-core": "dui/dui-core.min",
        "dui-templates": "dui/dui-templates.min",
        "dui-app": "dui/dui-app.min"
    },
    shim: {
        "angular": { exports: "angular" },
        "angular-locale": { deps: ["angular"] },
        "angular-route": { deps: ["angular", "angular-locale"] },
        "angular-ui-bootstrap": { deps: ["angular", "angular-locale"] },
        "dui-core": { deps: ["angular", "angular-locale", "angular-route", "angular-ui-bootstrap", "moment"], exports: "dui" },
        "dui-templates": { deps: ["dui-core"] },
        "dui-app": { deps: ["dui-core", "dui-templates"], exports: "app" }
    }
});
require(["angular", "dui-core", "dui-app"], function (angular, dui, app) {
    dui.config(["$logProvider", function ($logProvider) { $logProvider.debugEnabled(debug); }]);
    dui.run(["$locale", "$log", function ($locale, $log) {
            $log.debug("DUI core running (" + $locale.id + ")");
        }]);
    app.config(["$logProvider", function ($logProvider) { $logProvider.debugEnabled(debug); }]);
    app.run(["$log", function ($log) { $log.debug("DUI application \"" + app.name + "\" running"); }]);
    angular.element(document).ready(function () { angular.bootstrap(document, [app.name]); });
});
//# sourceMappingURL=dui.js.map