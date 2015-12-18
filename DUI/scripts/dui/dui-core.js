/// <reference path="../typings/requirejs/require.d.ts" />
/// <reference path="../typings/angularjs/angular.d.ts" />
/// <reference path="../typings/angularjs/angular-route.d.ts" />
/// <reference path="../typings/moment/moment.d.ts" />
"use strict";
var angular = require("angular"), moment = require("moment");
var DUI;
(function (DUI) {
    "use strict";
    function IsBlank(expression) {
        if (expression === undefined) {
            return true;
        }
        if (expression === null) {
            return true;
        }
        if (expression === NaN) {
            return true;
        }
        if (expression === {}) {
            return true;
        }
        if (expression === []) {
            return true;
        }
        if (String(expression).trim().length === 0) {
            return true;
        }
        return false;
    }
    DUI.IsBlank = IsBlank;
    function IfBlank(expression, defaultValue) {
        if (defaultValue === void 0) { defaultValue = undefined; }
        return (IsBlank(expression)) ? defaultValue : expression;
    }
    DUI.IfBlank = IfBlank;
    function Option(value, defaultValue, allowedValues) {
        if (defaultValue === void 0) { defaultValue = ""; }
        if (allowedValues === void 0) { allowedValues = []; }
        var option = angular.lowercase(String(value)).trim();
        if (allowedValues.length > 0) {
            var found = false;
            angular.forEach(allowedValues, function (allowedValue) {
                if (angular.lowercase(allowedValue).trim() === option) {
                    found = true;
                }
            });
            if (!found) {
                option = undefined;
            }
        }
        return IfBlank(option, angular.lowercase(IfBlank(defaultValue, "")).trim());
    }
    DUI.Option = Option;
    function BooleanAttr(iAttrs, name) {
        if (angular.isUndefined(iAttrs[name])) {
            return;
        }
        if (Option(iAttrs[name], "true") === "false") {
            return;
        }
        return true;
    }
    DUI.BooleanAttr = BooleanAttr;
    var Locale;
    (function (Locale) {
        var Service = (function () {
            function Service($locale, $filter, $log) {
                var _this = this;
                this.$locale = $locale;
                this.$filter = $filter;
                this.$log = $log;
                this.integerParser = function (value) {
                    if (IsBlank(value)) {
                        return value;
                    }
                    var s = String(value)
                        .replace(/\s/g, "\u00a0")
                        .replace(new RegExp("\\" + _this.$locale.NUMBER_FORMATS.GROUP_SEP, "g"), ",");
                    if (!(/^((?:[-+]?[1-9]\d{0,2})(?:(?:(?:\d{3})*)|(?:(?:\,\d{3})*)))$/.test(s) || s === "0")) {
                        return;
                    }
                    var n = parseInt(s.replace(/\,/g, ""), 10);
                    return (isNaN(n)) ? undefined : n;
                };
                this.integerFormatter = function (value) {
                    var n = Number(String(value));
                    return (isNaN(n)) ? undefined : _this.$filter("number")(n, 0);
                };
                this.decimalParser = function (value) {
                    if (IsBlank(value)) {
                        return value;
                    }
                    var s = String(value).split(_this.$locale.NUMBER_FORMATS.DECIMAL_SEP);
                    if (s.length > 2) {
                        return;
                    }
                    var i = _this.integerParser(s[0]);
                    if (IsBlank(i)) {
                        return;
                    }
                    if (s.length = 2) {
                        if (!/^(\d{2})$/.test(s[1])) {
                            return;
                        }
                    }
                    var n = parseFloat(String(i) + "." + IfBlank(s[1], "00"));
                    return (isNaN(n)) ? undefined : n;
                };
                this.decimalFormatter = function (value) {
                    var n = Number(String(value));
                    return (isNaN(n)) ? undefined : _this.$filter("number")(n, 2);
                };
            }
            Service.$inject = ["$locale", "$filter", "$log"];
            return Service;
        })();
        Locale.Service = Service;
    })(Locale = DUI.Locale || (DUI.Locale = {}));
    var Form;
    (function (Form) {
        var Controller = (function () {
            function Controller($scope, $window, $route, $routeParams, $filter, $log) {
                var _this = this;
                this.$scope = $scope;
                this.$window = $window;
                this.$route = $route;
                this.$routeParams = $routeParams;
                this.$filter = $filter;
                this.$log = $log;
                this.tabs = [];
                this.addTab = function (heading, sort) {
                    _this.tabs.push(Object.create(null, {
                        heading: { get: function () { return heading; } },
                        sort: { get: function () { return sort; } },
                        active: { value: false, writable: true }
                    }));
                    return _this.tabs[_this.tabs.length - 1];
                };
                this.removeTab = function (tab) {
                    var i = _this.tabs.indexOf(tab);
                    if (i >= 0) {
                        _this.tabs.splice(i, 1);
                    }
                };
                this.activateTab = function (tab) {
                    angular.forEach(_this.tabs, function (tab) { tab.active = false; });
                    tab.active = true;
                };
                this.activateFirstTab = function () {
                    var activated = false;
                    if (!IsBlank(_this.$routeParams.tabHeading)) {
                        angular.forEach(_this.tabs, function (tab) {
                            if (tab.heading === _this.$routeParams.tabHeading) {
                                _this.activateTab(tab);
                                activated = true;
                            }
                        });
                    }
                    if (!activated) {
                        _this.activateTab(_this.$filter("orderBy")(_this.tabs, "sort")[0]);
                    }
                };
            }
            Object.defineProperty(Controller.prototype, "hasTabs", {
                get: function () { return this.tabs.length > 0; },
                enumerable: true,
                configurable: true
            });
            Object.defineProperty(Controller.prototype, "isDirty", {
                get: function () { return this.$scope.form.$dirty; },
                enumerable: true,
                configurable: true
            });
            Controller.$inject = ["$scope", "$window", "$route", "$routeParams", "$filter", "$log"];
            return Controller;
        })();
        Form.Controller = Controller;
        function DirectiveFactory() {
            var factory = function ($window, $location, $route, $filter, $log) {
                return {
                    restrict: "E",
                    templateUrl: "duiForm.html",
                    transclude: true,
                    scope: {
                        heading: "@", subheading: "@",
                        loadProc: "@load", saveProc: "@save", deleteProc: "@delete",
                        backRoute: "@back"
                    },
                    controller: Controller,
                    controllerAs: "duiFormCtrl",
                    require: "duiForm",
                    link: function ($scope, iElement, iAttrs, duiFormCtrl) {
                        Object.defineProperties($scope, {
                            "isEditable": { get: function () { return !IsBlank($scope.saveProc); } },
                            "isDeletable": { get: function () { return !IsBlank($scope.deleteProc); } },
                            "hasError": { get: function () { return $scope.form.$dirty && $scope.form.$invalid; } }
                        });
                        $scope.back = function () {
                            if (IsBlank($scope.backRoute)) {
                                $window.history.back();
                            }
                            else {
                                $location.path($scope.backRoute);
                            }
                        };
                        $scope.undo = function () { $route.reload(); };
                        if (duiFormCtrl.hasTabs) {
                            duiFormCtrl.activateFirstTab();
                        }
                    }
                };
            };
            factory.$inject = ["$window", "$location", "$route", "$filter", "$log"];
            return factory;
        }
        Form.DirectiveFactory = DirectiveFactory;
    })(Form = DUI.Form || (DUI.Form = {}));
    var FormTab;
    (function (FormTab) {
        function DirectiveFactory() {
            var factory = function () {
                return {
                    restrict: "E",
                    templateUrl: "duiFormTab.html",
                    transclude: true,
                    scope: { heading: "@", sort: "@" },
                    require: "^^duiForm",
                    link: function ($scope, iElement, iAttrs, duiFormCtrl) {
                        var tab = duiFormCtrl.addTab($scope.heading, parseInt($scope.sort, 10));
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
        FormTab.DirectiveFactory = DirectiveFactory;
    })(FormTab = DUI.FormTab || (DUI.FormTab = {}));
    var Label;
    (function (Label) {
        function DirectiveFactory() {
            var factory = function () {
                return {
                    restrict: "E",
                    templateUrl: "duiLabel.html",
                    transclude: true,
                    scope: { text: "@" },
                    require: "^^duiForm",
                    link: function ($scope, iElement, iAttrs, duiFormCtrl) {
                        Object.defineProperty($scope, "hasError", {
                            get: function () { return (duiFormCtrl.isDirty || $scope.form.$dirty) && $scope.form.$invalid; }
                        });
                    }
                };
            };
            return factory;
        }
        Label.DirectiveFactory = DirectiveFactory;
    })(Label = DUI.Label || (DUI.Label = {}));
    var Input;
    (function (Input) {
        function DirectiveFactory() {
            var factory = function (duiLocale) {
                return {
                    restrict: "A",
                    require: "ngModel",
                    link: function ($scope, iElement, iAttrs, ngModelCtrl) {
                        if (!iElement.hasClass("form-control")) {
                            iElement.addClass("form-control");
                        }
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
        Input.DirectiveFactory = DirectiveFactory;
    })(Input = DUI.Input || (DUI.Input = {}));
    var CurrencyField;
    (function (CurrencyField) {
        function DirectiveFactory() {
            var factory = function ($locale) {
                return {
                    restrict: "E",
                    scope: { symbol: "@", ngModel: "=" },
                    templateUrl: "duiCurrency.html",
                    link: function ($scope, iElement, iAttrs) {
                        Object.defineProperties($scope, {
                            "defaultSymbol": {
                                get: function () { return $locale.NUMBER_FORMATS.CURRENCY_SYM; }
                            },
                            "required": {
                                get: function () { return DUI.BooleanAttr(iAttrs, "required"); }
                            }
                        });
                    }
                };
            };
            factory.$inject = ["$locale"];
            return factory;
        }
        CurrencyField.DirectiveFactory = DirectiveFactory;
    })(CurrencyField = DUI.CurrencyField || (DUI.CurrencyField = {}));
    var DateField;
    (function (DateField) {
        function DirectiveFactory() {
            var factory = function ($locale) {
                return {
                    restrict: "E",
                    templateUrl: "duiDate.html",
                    scope: { ngModel: "=ngModel" },
                    link: function ($scope, iElement, iAttrs) {
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
                        var $modelWatcher = $scope.$watch("ngModel", function (newValue, oldValue) {
                            if (newValue === oldValue) {
                                return;
                            }
                            var $modelValue = (IsBlank($scope.ngModel)) ? undefined : moment($scope.ngModel).toDate();
                            var $viewValue = (IsBlank($scope.uibModel)) ? undefined : moment($scope.uibModel).toDate();
                            if ($modelValue !== $viewValue) {
                                $scope.uibModel = $modelValue;
                            }
                        });
                        var $viewWatcher = $scope.$watch("uibModel", function (newValue, oldValue) {
                            if (newValue === oldValue) {
                                return;
                            }
                            var $modelValue = (IsBlank($scope.ngModel)) ? undefined : moment($scope.ngModel).format("YYYY-MM-DD");
                            var $viewValue = (IsBlank($scope.uibModel)) ? undefined : moment($scope.uibModel).format("YYYY-MM-DD");
                            if ($modelValue !== $viewValue) {
                                $scope.ngModel = $viewValue;
                            }
                        });
                        $scope.$on("$destroy", function () { $modelWatcher(); $viewWatcher(); });
                    }
                };
            };
            factory.$inject = ["$locale"];
            return factory;
        }
        DateField.DirectiveFactory = DirectiveFactory;
    })(DateField = DUI.DateField || (DUI.DateField = {}));
})(DUI || (DUI = {}));
var dui = angular.module("dui", ["ngRoute", "ui.bootstrap"]);
dui.service("duiLocale", DUI.Locale.Service);
dui.directive("duiForm", DUI.Form.DirectiveFactory());
dui.directive("duiFormTab", DUI.FormTab.DirectiveFactory());
dui.directive("duiLabel", DUI.Label.DirectiveFactory());
dui.directive("duiInput", DUI.Input.DirectiveFactory());
dui.directive("duiCurrency", DUI.CurrencyField.DirectiveFactory());
dui.directive("duiDate", DUI.DateField.DirectiveFactory());
dui.run(["$locale", "$log", function ($locale, $log) {
        moment.locale($locale.id);
    }]);
//# sourceMappingURL=dui-core.js.map