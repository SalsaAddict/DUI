/// <reference path="../typings/requirejs/require.d.ts" />
/// <reference path="../typings/angularjs/angular.d.ts" />
/// <reference path="../typings/angularjs/angular-route.d.ts" />
"use strict";
var angular = require("angular"), dui = require("dui-core");
var app = angular.module("Advent", ["ngRoute", "ui.bootstrap", dui.name]);
app.config(["$routeProvider", function ($routeProvider) {
        var createRoute = function (name, when, templateUrl) {
            if (when.indexOf("/:tabHeading?") < 0) {
                when += "/:tabHeading?";
            }
            $routeProvider.when(when, { name: name, templateUrl: templateUrl, caseInsensitiveMatch: true });
        };
        createRoute("Home", "/home/:IncidentId?/:ClaimantId?/:ClaimId?", "views/home.html");
        $routeProvider.otherwise({ redirectTo: "/home" });
    }]);
//# sourceMappingURL=dui-app.js.map