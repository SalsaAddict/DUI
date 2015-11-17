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
    var InputDate;
    (function (InputDate) {
        function DirectiveFactory() {
            var factory = function ($locale, $filter) {
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
                        $scope.model = function (value) {
                            if (arguments.length) {
                                $scope.ngModel = (IsBlank(value))
                                    ? undefined : moment(new Date(value)).format("YYYY-MM-DD");
                            }
                            else {
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
        InputDate.DirectiveFactory = DirectiveFactory;
    })(InputDate = DUI.InputDate || (DUI.InputDate = {}));
})(DUI || (DUI = {}));
var dui = angular.module("dui", ["ngRoute", "ui.bootstrap"]);
dui.directive("duiDate", DUI.InputDate.DirectiveFactory());
dui.run(["$locale", "$log", function ($locale, $log) {
        moment.locale($locale.id);
    }]);
//# sourceMappingURL=dui-core.js.map