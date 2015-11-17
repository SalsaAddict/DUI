/// <reference path="../typings/requirejs/require.d.ts" />
/// <reference path="../typings/angularjs/angular.d.ts" />
/// <reference path="../typings/angularjs/angular-route.d.ts" />
/// <reference path="../typings/moment/moment.d.ts" />
"use strict";

var dui: angular.IModule = require("dui-core");

dui.run(["$templateCache", "$log", function (
    $templateCache: angular.ITemplateCacheService,
    $log: angular.ILogService) {

    $templateCache.put("duiLabel",
        "<div class=\"form-group\" ng-class=\"{'has-error': hasError}\" ng-form=\"form\">" +
        "<label class=\"control-label col-sm-3\">{{label}}</label>" +
        "<div class=\"col-sm-9\" ng-transclude></div>" +
        "</div>");

    $templateCache.put("duiDate.html",
        "<div class=\"input-group\">" +
        "<input type=\"text\" ng-model=\"model\" ng-model-options=\"{ getterSetter: true }\" ng-required=\"isRequired\" " +
        "class=\"form-control\" uib-datepicker-popup=\"{{format}}\" is-open=\"isOpen\" placeholder=\"{{placeholder}}\" />" +
        "<span class=\"input-group-btn\">" +
        "<button type=\"button\" class=\"btn btn-default\" ng-click=\"isOpen = !isOpen\">" +
        "<i class=\"fa fa-calendar\"></i>" +
        "</button>" +
        "</span>" +
        "</div>");

    $log.debug("DUI templates loaded");

}]);

