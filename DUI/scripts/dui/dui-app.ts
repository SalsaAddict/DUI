/// <reference path="../typings/requirejs/require.d.ts" />
/// <reference path="../typings/angularjs/angular.d.ts" />
/// <reference path="../typings/angularjs/angular-route.d.ts" />
"use strict";

var angular: angular.IAngularStatic = require("angular"),
    dui: angular.IModule = require("dui-core");

var app: angular.IModule = angular.module("Advent", ["ngRoute", "ui.bootstrap", dui.name]);

app.config(["$routeProvider", function ($routeProvider: angular.route.IRouteProvider) {
    var createRoute = (name: string, when: string, templateUrl: string) => {
        if (when.indexOf("/:tabHeading?") < 0) { when += "/:tabHeading?"; }
        $routeProvider.when(when, { name: name, templateUrl: templateUrl, caseInsensitiveMatch: true });
    };
    createRoute("Home", "/home/:IncidentId?/:ClaimantId?/:ClaimId?", "views/home.html");
    $routeProvider.otherwise({ redirectTo: "/home" });
}]);
