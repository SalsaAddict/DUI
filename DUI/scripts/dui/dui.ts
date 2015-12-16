/// <reference path="../typings/requirejs/require.d.ts" />
"use strict";

var defaultLocaleId: string = "fr-fr",
    debug: boolean = true;

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

require(["angular", "dui-core", "dui-app"], function (angular: angular.IAngularStatic, dui: angular.IModule, app: angular.IModule) {
    dui.config(["$logProvider", function ($logProvider: angular.ILogProvider) { $logProvider.debugEnabled(debug); }]);
    dui.run(["$locale", "$log", function ($locale: angular.ILocaleService, $log: angular.ILogService) {
        $log.debug("DUI core running (" + $locale.id + ")");
    }]);
    app.config(["$logProvider", function ($logProvider: angular.ILogProvider) { $logProvider.debugEnabled(debug); }]);
    app.run(["$log", function ($log: angular.ILogService) { $log.debug("DUI application \"" + app.name + "\" running"); }]);
    angular.element(document).ready(function () { angular.bootstrap(document, [app.name]); });
});
