/// <reference path="../typings/requirejs/require.d.ts" />
/// <reference path="../typings/angularjs/angular.d.ts" />
/// <reference path="../typings/angularjs/angular-route.d.ts" />
/// <reference path="../typings/moment/moment.d.ts" />
"use strict";
var angular = require("angular"), dui = require("dui-core");
var app = angular.module("Advent", ["ngRoute", "ui.bootstrap", dui.name]);
app.config(["$routeProvider", function ($routeProvider) {
        $routeProvider
            .when("/home/:IncidentId?/:ClaimantId?/:ClaimId?", { name: "Home", templateUrl: "views/home.html" })
            .otherwise({ redirectTo: "/home" });
    }]);
//# sourceMappingURL=dui-app.js.map