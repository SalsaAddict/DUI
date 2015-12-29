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
    export module Locale {
        export class Service {
            static $inject: string[] = ["$locale", "$filter", "$log"];
            constructor(
                private $locale: angular.ILocaleService,
                private $filter: angular.IFilterService,
                private $log: angular.ILogService) { }
            integerParser = (value: any): number => {
                if (IsBlank(value)) { return value; }
                var s: string = String(value)
                    .replace(/\s/g, "\u00a0")
                    .replace(new RegExp("\\" + this.$locale.NUMBER_FORMATS.GROUP_SEP, "g"), ",");
                if (!(/^((?:[-+]?[1-9]\d{0,2})(?:(?:(?:\d{3})*)|(?:(?:\,\d{3})*)))$/.test(s) || s === "0")) { return; }
                var n: number = parseInt(s.replace(/\,/g, ""), 10);
                return (isNaN(n)) ? undefined : n;
            }
            integerFormatter = (value: any): string => {
                var n: number = Number(String(value));
                return (isNaN(n)) ? undefined : this.$filter("number")(n, 0);
            }
            decimalParser = (value: any): number => {
                if (IsBlank(value)) { return value; }
                var s: string[] = String(value).split(this.$locale.NUMBER_FORMATS.DECIMAL_SEP);
                if (s.length > 2) { return; }
                var i: number = this.integerParser(s[0]);
                if (IsBlank(i)) { return; }
                if (s.length = 2) { if (!/^(\d{2})$/.test(s[1])) { return; } }
                var n: number = parseFloat(String(i) + "." + IfBlank(s[1], "00"));
                return (isNaN(n)) ? undefined : n;
            }
            decimalFormatter = (value: any): string => {
                var n: number = Number(String(value));
                return (isNaN(n)) ? undefined : this.$filter("number")(n, 2);
            }
        }
    }
    export module Parameter {
        export interface IScope extends angular.IScope {
            type: string; value: string; required: boolean;
        }
    }
    export module Form {
        export interface IScope extends angular.IScope {
            heading: string;
            subheading: string;
            loadProc: string; saveProc: string; deleteProc: string; backRoute: string;
            form: angular.IFormController;
            hasError: boolean;
            back: Function;
            undo: Function;
        }
        export interface ITab { heading: string; sort: number; active: boolean; }
        export interface IRouteParamsService extends angular.route.IRouteParamsService { tabHeading?: string; }
        export class Controller {
            static $inject: string[] = ["$scope", "$window", "$route", "$routeParams", "$filter", "$log"];
            tabs: ITab[] = [];
            constructor(
                private $scope: IScope,
                private $window: angular.IWindowService,
                private $route: angular.route.IRouteService,
                private $routeParams: IRouteParamsService,
                private $filter: angular.IFilterService,
                private $log: angular.ILogService) { }
            get hasTabs(): boolean { return this.tabs.length > 0; }
            addTab = (heading: string, sort: number) => {
                this.tabs.push(Object.create(null, {
                    heading: { get: function () { return heading; } },
                    sort: { get: function () { return sort; } },
                    active: { value: false, writable: true }
                }));
                return this.tabs[this.tabs.length - 1];
            };
            removeTab = (tab: ITab) => {
                var i: number = this.tabs.indexOf(tab);
                if (i >= 0) { this.tabs.splice(i, 1); }
            };
            activateTab = (tab: ITab) => {
                angular.forEach(this.tabs, function (tab: ITab) { tab.active = false; });
                tab.active = true;
            }
            activateFirstTab = () => {
                var activated: boolean = false;
                if (!IsBlank(this.$routeParams.tabHeading)) {
                    angular.forEach(this.tabs, (tab: ITab) => {
                        if (tab.heading === this.$routeParams.tabHeading) {
                            this.activateTab(tab);
                            activated = true;
                        }
                    });
                }
                if (!activated) { this.activateTab(this.$filter("orderBy")(this.tabs, "sort")[0]); }
            }
            get isDirty(): boolean { return this.$scope.form.$dirty; }
        }
        export function DirectiveFactory(): angular.IDirectiveFactory {
            var factory: angular.IDirectiveFactory = function (
                $window: angular.IWindowService,
                $location: angular.ILocationService,
                $route: angular.route.IRouteService,
                $filter: angular.IFilterService,
                $log: angular.ILogService) {
                return {
                    restrict: "E",
                    templateUrl: "duiForm.html",
                    transclude: true,
                    scope: <IScope> {
                        heading: "@", subheading: "@",
                        loadProc: "@load", saveProc: "@save", deleteProc: "@delete",
                        backRoute: "@back"
                    },
                    controller: Controller,
                    controllerAs: "duiFormCtrl",
                    require: "duiForm",
                    link: function (
                        $scope: IScope,
                        iElement: angular.IAugmentedJQuery,
                        iAttrs: angular.IAttributes,
                        duiFormCtrl: Controller) {
                        Object.defineProperties($scope, {
                            "isEditable": { get: function () { return !IsBlank($scope.saveProc); } },
                            "isDeletable": { get: function () { return !IsBlank($scope.deleteProc); } },
                            "hasError": { get: function () { return $scope.form.$dirty && $scope.form.$invalid; } }
                        });
                        $scope.back = function () {
                            if (IsBlank($scope.backRoute)) {
                                $window.history.back();
                            } else {
                                $location.path($scope.backRoute);
                            }
                        };
                        $scope.undo = function () { $route.reload(); };
                        if (duiFormCtrl.hasTabs) { duiFormCtrl.activateFirstTab(); }
                    }
                };
            };
            factory.$inject = ["$window", "$location", "$route", "$filter", "$log"];
            return factory;
        }
    }
    export module FormTab {
        export interface IScope extends angular.IScope { heading: string; sort: string; form: angular.IFormController; }
        export function DirectiveFactory(): angular.IDirectiveFactory {
            var factory: angular.IDirectiveFactory = function () {
                return {
                    restrict: "E",
                    templateUrl: "duiFormTab.html",
                    transclude: true,
                    scope: <IScope> { heading: "@", sort: "@" },
                    require: "^^duiForm",
                    link: function (
                        $scope: IScope,
                        iElement: angular.IAugmentedJQuery,
                        iAttrs: angular.IAttributes,
                        duiFormCtrl: Form.Controller) {
                        var tab: Form.ITab = duiFormCtrl.addTab($scope.heading, parseInt($scope.sort, 10));
                        Object.defineProperty(tab, "hasError", {
                            get: function () { return duiFormCtrl.isDirty && $scope.form.$invalid; }
                        });
                        Object.defineProperty($scope, "isActive", { get: function () { return tab.active; } });
                        $scope.$on("$destroy", function () { duiFormCtrl.removeTab(tab); tab = undefined; });
                    }
                };
            };
            return factory;
        }
    }
    export module Label {
        export interface IScope extends angular.IScope {
            text: string;
            form: angular.IFormController;
            hasError: boolean;
        }
        export function DirectiveFactory(): angular.IDirectiveFactory {
            var factory: angular.IDirectiveFactory = function () {
                return {
                    restrict: "E",
                    templateUrl: "duiLabel.html",
                    transclude: true,
                    scope: <IScope> { text: "@" },
                    require: "^^duiForm",
                    link: function (
                        $scope: IScope,
                        iElement: angular.IAugmentedJQuery,
                        iAttrs: angular.IAttributes,
                        duiFormCtrl: Form.Controller) {
                        Object.defineProperties($scope, {
                            "hasError": {
                                get: function () { return (duiFormCtrl.isDirty || $scope.form.$dirty) && $scope.form.$invalid; }
                            },
                            "message": {
                                get: function () {
                                    if (!$scope.hasError) { return $scope.text; }
                                    if ($scope.form.$error.date) { return "The specified date is not valid"; }
                                    if ($scope.form.$error.required) { return "This field is required"; }
                                    return "The supplied value is not valid";
                                }
                            }
                        });
                    }
                };
            };
            return factory;
        }
    }
    export module Input {
        export interface IAttributes extends angular.IAttributes { duiInput: string; }
        export function DirectiveFactory(): angular.IDirectiveFactory {
            var factory: angular.IDirectiveFactory = function (duiLocale: DUI.Locale.Service) {
                return {
                    restrict: "A",
                    require: "ngModel",
                    link: function (
                        $scope: angular.IScope,
                        iElement: angular.IAugmentedJQuery,
                        iAttrs: IAttributes,
                        ngModelCtrl: angular.INgModelController) {
                        if (!iElement.hasClass("form-control")) { iElement.addClass("form-control"); }
                        switch (iAttrs.duiInput) {
                            case "integer":
                                iElement.attr("placeholder", duiLocale.integerFormatter(9999).replace(/\9/g, "#"));
                                ngModelCtrl.$formatters.unshift(duiLocale.integerFormatter);
                                ngModelCtrl.$parsers.unshift(duiLocale.integerParser);
                                break;
                            case "decimal":
                                iElement.attr("placeholder", duiLocale.decimalFormatter(9999.99).replace(/\9/g, "#"));
                                ngModelCtrl.$formatters.unshift(duiLocale.decimalFormatter);
                                ngModelCtrl.$parsers.unshift(duiLocale.decimalParser);
                                break;
                        }
                    }
                };
            };
            factory.$inject = ["duiLocale"];
            return factory;
        }
    }
    export module CurrencyField {
        export interface IScope extends angular.IScope { symbol: string; ngModel: any; required: boolean; }
        export interface IAttributes extends angular.IAttributes { required: string; }
        export function DirectiveFactory(): angular.IDirectiveFactory {
            var factory: angular.IDirectiveFactory = function ($locale: angular.ILocaleService) {
                return {
                    restrict: "E",
                    scope: <IScope> { symbol: "@", ngModel: "=" },
                    templateUrl: "duiCurrency.html",
                    link: function (
                        $scope: IScope,
                        iElement: angular.IAugmentedJQuery,
                        iAttrs: IAttributes) {
                        Object.defineProperties($scope, {
                            "defaultSymbol": {
                                get: function () { return $locale.NUMBER_FORMATS.CURRENCY_SYM; }
                            },
                            "isRequired": {
                                get: function () { return DUI.BooleanAttr(iAttrs, "required"); }
                            }
                        });
                    }
                };
            };
            factory.$inject = ["$locale"];
            return factory;
        }
    }
    export module DateField {
        export interface IScope extends angular.IScope {
            ngModel: any;
            uibModel: Date;
            format: string;
            placeholder: string;
            isOpen: boolean;
            isRequired: boolean;
        }
        export function DirectiveFactory(): angular.IDirectiveFactory {
            var factory: angular.IDirectiveFactory = function (
                $locale: angular.ILocaleService) {
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
                        $scope.uibModel = (IsBlank($scope.ngModel)) ? undefined : moment($scope.ngModel).toDate();
                        var $modelWatcher = $scope.$watch("ngModel", function (newValue: string, oldValue: string) {
                            if (newValue === oldValue) { return; }
                            var $modelValue: Date = (IsBlank($scope.ngModel)) ? undefined : moment($scope.ngModel).toDate();
                            var $viewValue: Date = (IsBlank($scope.uibModel)) ? undefined : moment($scope.uibModel).toDate();
                            if ($modelValue !== $viewValue) { $scope.uibModel = $modelValue; }
                        });
                        var $viewWatcher = $scope.$watch("uibModel", function (newValue: string, oldValue: string) {
                            if (newValue === oldValue) { return; }
                            var $modelValue: string = (IsBlank($scope.ngModel)) ? undefined : moment($scope.ngModel).format("YYYY-MM-DD");
                            var $viewValue: string = (IsBlank($scope.uibModel)) ? undefined : moment($scope.uibModel).format("YYYY-MM-DD");
                            if ($modelValue !== $viewValue) { $scope.ngModel = $viewValue; }
                        });
                        $scope.$on("$destroy", function () { $modelWatcher(); $viewWatcher(); });
                    }
                };
            };
            factory.$inject = ["$locale"];
            return factory;
        }
    }
}

var dui: angular.IModule = angular.module("dui", ["ngRoute", "ui.bootstrap"]);

dui.service("duiLocale", DUI.Locale.Service);
dui.directive("duiForm", DUI.Form.DirectiveFactory());
dui.directive("duiFormTab", DUI.FormTab.DirectiveFactory());
dui.directive("duiLabel", DUI.Label.DirectiveFactory());
dui.directive("duiInput", DUI.Input.DirectiveFactory());
dui.directive("duiCurrency", DUI.CurrencyField.DirectiveFactory());
dui.directive("duiDate", DUI.DateField.DirectiveFactory());

dui.run(["$locale", "$log", function ($locale: angular.ILocaleService, $log: angular.ILogService) {
    moment.locale($locale.id);
}]);