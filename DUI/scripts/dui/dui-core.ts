/// <reference path="../typings/requirejs/require.d.ts" />
/// <reference path="../typings/angularjs/angular.d.ts" />
/// <reference path="../typings/angularjs/angular-route.d.ts" />
/// <reference path="../typings/moment/moment.d.ts" />
"use strict";

var angular: angular.IAngularStatic = require("angular"),
    moment: moment.MomentStatic = require("moment");

module DUI {
    "use strict";
    export function IsBlank(expression: any): boolean {
        if (expression === undefined) { return true; }
        if (expression === null) { return true; }
        if (expression === NaN) { return true; }
        if (expression === {}) { return true; }
        if (expression === []) { return true; }
        if (String(expression).trim().length === 0) { return true; }
        return false;
    }
    export function IfBlank(expression: any, defaultValue: any = undefined): any {
        return (IsBlank(expression)) ? defaultValue : expression;
    }
    export function Option(value: any, defaultValue: string = "", allowedValues: string[] = []): string {
        var option: string = angular.lowercase(String(value)).trim();
        if (allowedValues.length > 0) {
            var found: boolean = false;
            angular.forEach(allowedValues, (allowedValue: string) => {
                if (angular.lowercase(allowedValue).trim() === option) { found = true; }
            });
            if (!found) { option = undefined; }
        }
        return IfBlank(option, angular.lowercase(IfBlank(defaultValue, "")).trim());
    }
    export function BooleanAttr(iAttrs: angular.IAttributes, name: string) {
        if (angular.isUndefined(iAttrs[name])) { return; }
        if (Option(iAttrs[name], "true") === "false") { return; }
        return true;
    }
    export module Label {
        export interface IScope extends angular.IScope {
        }
    }
    export module InputDate {
        export interface IScope extends angular.IScope {
            ngModel: any; model: Function; format: string; placeholder: string; isOpen: boolean;
        }
        export function DirectiveFactory(): angular.IDirectiveFactory {
            var factory: angular.IDirectiveFactory = function (
                $locale: angular.ILocaleService,
                $filter: angular.IFilterService) {
                return {
                    restrict: "E",
                    templateUrl: "duiDate.html",
                    scope: <IScope> { ngModel: "=ngModel" },
                    link: function (
                        $scope: IScope,
                        iElement: angular.IAugmentedJQuery,
                        iAttrs: angular.IAttributes) {
                        Object.defineProperties($scope, {
                            format: {
                                get: function () {
                                    switch ($locale.id) {
                                        case "en-us": return "MM/dd/yyyy";
                                        default: return "dd/MM/yyyy";
                                    }
                                }
                            },
                            placeholder: { get: function () { return angular.lowercase($scope.format); } },
                            isOpen: { value: false, writable: true },
                            isRequired: { get: function () { return BooleanAttr(iAttrs, "required"); } }
                        });
                        $scope.model = function (value?: any) {
                            if (arguments.length) {
                                $scope.ngModel = (IsBlank(value))
                                    ? undefined : moment(new Date(value)).format("YYYY-MM-DD");
                            } else {
                                return (IsBlank($scope.ngModel))
                                    ? undefined : moment(new Date($scope.ngModel)).toISOString();
                            }
                        };
                    }
                };
            };
            factory.$inject = ["$locale", "$filter"];
            return factory;
        }
    }
}

var dui: angular.IModule = angular.module("dui", ["ngRoute", "ui.bootstrap"]);

dui.directive("duiDate", DUI.InputDate.DirectiveFactory());

dui.run(["$locale", "$log", function ($locale: angular.ILocaleService, $log: angular.ILogService) {
    moment.locale($locale.id);
}]);