/// <reference path="../typings/requirejs/require.d.ts" />
/// <reference path="../typings/angularjs/angular.d.ts" />
/// <reference path="../typings/angularjs/angular-route.d.ts" />
/// <reference path="../typings/moment/moment.d.ts" />
"use strict";
var dui = require("dui-core");
dui.run(["$templateCache", "$log", function ($templateCache, $log) {
        $templateCache.put("duiForm.html", "<div class=\"panel panel-default dui-form\" ng-form=\"form\">" +
            "<div class=\"panel-heading\">" +
            "<h4 ng-class=\"{'text-danger': hasError}\">{{heading}}" +
            "<span ng-if=\"hasError\"> <i class=\"fa fa-exclamation-triangle\"></i></span>" +
            "<span ng-if=\"subheading\"><br /><small>{{subheading}}</small></span></h4>" +
            "</div>" +
            "<div class=\"panel-body form-horizontal\">" +
            "<ul class=\"nav nav-tabs\" ng-if=\"duiFormCtrl.hasTabs\">" +
            "<li ng-repeat=\"tab in duiFormCtrl.tabs | orderBy: 'sort'\" ng-class=\"{active: tab.active}\">" +
            "<a href=\"\" ng-click=\"duiFormCtrl.activateTab(tab)\">" +
            "<span  ng-class=\"{'text-danger': tab.hasError}\">{{tab.heading}}" +
            "<span ng-if=\"tab.hasError\"> <i class=\"fa fa-exclamation-triangle\"></i></span></span>" +
            "</a>" +
            "</li>" +
            "</ul>" +
            "<fieldset ng-disabled=\"!isEditable\" ng-transclude></fieldset>" +
            "</div>" +
            "<div class=\"panel-footer clearfix\">" +
            "<div class=\"pull-right\">" +
            "<div ng-if=\"form.$pristine\" class=\"btn-group\">" +
            "<button ng-if=\"isDeletable\" type=\"button\" class=\"btn btn-danger\" ng-click=\"delete()\">" +
            "<i class=\"fa fa-trash\"></i> Delete</button>" +
            "<button type=\"button\" class=\"btn btn-default\" ng-click=\"back()\">" +
            "<i class=\"fa fa-chevron-circle-left\"></i> Back</button>" +
            "</div>" +
            "<div ng-if=\"form.$dirty\" class=\"btn-group\">" +
            "<button type=\"button\" class=\"btn btn-warning\" ng-click=\"undo()\">" +
            "<i class=\"fa fa-undo\"></i> Undo</button>" +
            "<button type=\"button\" class=\"btn\" ng-disabled=\"hasError\" ng-click=\"save()\" " +
            "ng-class=\"{'btn-primary': !hasError, 'btn-default': hasError}\">" +
            "<i class=\"fa fa-save\"></i> Save</button>" +
            "</div>" +
            "</div>" +
            "</div>" +
            "</div>");
        $templateCache.put("duiFormTab.html", "<div id=\"tab{{index}}\" ng-show=\"isActive\" ng-form=\"form\">" +
            "<br /><div ng-transclude></div></div>");
        $templateCache.put("duiLabel.html", "<div class=\"form-group\" ng-class=\"{'has-error': hasError}\" ng-form=\"form\">" +
            "<label class=\"control-label col-sm-3\">{{text}}" +
            "<span ng-if=\"hasError\"> <i class=\"fa fa-exclamation-triangle\"></i></span>" +
            "</label>" +
            "<div class=\"col-sm-9\" ng-transclude></div>" +
            "</div>");
        $templateCache.put("duiCurrency.html", "<div class=\"input-group\">" +
            "<span class=\"input-group-addon\">{{symbol || defaultSymbol}}</span>" +
            "<input type=\"text\" ng-model=\"ngModel\" dui-input=\"decimal\" ng-required=\"isRequired\" />" +
            "</div>");
        $templateCache.put("duiDate.html", "<div class=\"input-group\">" +
            "<input type=\"text\" ng-model=\"uibModel\" ng-required=\"isRequired\" " +
            "class=\"form-control\" uib-datepicker-popup=\"{{format}}\" is-open=\"isOpen\" placeholder=\"{{placeholder}}\" />" +
            "<span class=\"input-group-btn\">" +
            "<button type=\"button\" class=\"btn btn-default\" ng-click=\"isOpen = !isOpen\">" +
            "<i class=\"fa fa-calendar\"></i>" +
            "</button>" +
            "</span>" +
            "</div>");
        $log.debug("DUI templates loaded");
    }]);
//# sourceMappingURL=dui-templates.js.map