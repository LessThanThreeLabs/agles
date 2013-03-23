// Generated by IcedCoffeeScript 1.3.3e
(function() {
  'use strict';

  describe('Koality directives', function() {
    describe('dropdown directive', function() {
      var element, scope;
      element = null;
      scope = null;
      beforeEach(module('koality.directive'));
      beforeEach(function() {
        return inject(function($rootScope, $compile) {
          scope = $rootScope.$new();
          element = angular.element('<dropdown alignment="left" dropdown-options="dropdownOptions" dropdown-show="dropdownShow" dropdown-option-click="handleClick(dropdownOption)" />');
          $compile(element)(scope);
          return scope.$digest();
        });
      });
      it('should render the correct number of options', function() {
        var createOption, numOptions, options;
        createOption = function(optionNum) {
          return {
            title: optionNum,
            name: optionNum
          };
        };
        numOptions = 5;
        scope.$apply(function() {
          var optionNum;
          return scope.dropdownOptions = (function() {
            var _i, _results;
            _results = [];
            for (optionNum = _i = 0; 0 <= numOptions ? _i < numOptions : _i > numOptions; optionNum = 0 <= numOptions ? ++_i : --_i) {
              _results.push(createOption(optionNum));
            }
            return _results;
          })();
        });
        options = element.find('.prettyDropdownOption');
        expect(options.length).toBe(numOptions);
        numOptions = 7;
        scope.$apply(function() {
          var optionNum;
          return scope.dropdownOptions = (function() {
            var _i, _results;
            _results = [];
            for (optionNum = _i = 0; 0 <= numOptions ? _i < numOptions : _i > numOptions; optionNum = 0 <= numOptions ? ++_i : --_i) {
              _results.push(createOption(optionNum));
            }
            return _results;
          })();
        });
        options = element.find('.prettyDropdownOption');
        return expect(options.length).toBe(numOptions);
      });
      return it('should handle option click properly', function() {
        var options;
        scope.$apply(function() {
          return scope.dropdownOptions = [
            {
              title: 'First',
              name: 'first'
            }, {
              title: 'Second',
              name: 'second'
            }
          ];
        });
        scope.handleClick = function(dropdownOptionName) {};
        spyOn(scope, 'handleClick');
        options = element.find('.prettyDropdownOption');
        options.eq(0).click();
        expect(scope.handleClick).toHaveBeenCalledWith('first');
        expect(scope.handleClick.calls.length).toBe(1);
        options.eq(1).click();
        expect(scope.handleClick).toHaveBeenCalledWith('second');
        expect(scope.handleClick.calls.length).toBe(2);
        options.eq(1).click();
        return expect(scope.handleClick.calls.length).toBe(3);
      });
    });
    describe('modal directive', function() {
      var element, scope;
      element = null;
      scope = null;
      beforeEach(module('koality.directive'));
      return it('should become invisible when background is clicked', function() {
        inject(function($rootScope, $compile) {
          scope = $rootScope.$new();
          scope.modalVisible = true;
          element = angular.element('<modal modal-visible="modalVisible">blah</modal>');
          $compile(element)(scope);
          return scope.$digest();
        });
        expect(scope.modalVisible).toBe(true);
        element.find('.prettyModalBackdrop').click();
        return expect(scope.modalVisible).toBe(false);
      });
    });
    return describe('tooltip directive', function() {
      var element, scope;
      element = null;
      scope = null;
      beforeEach(module('koality.directive'));
      it('should render the correct tooltip text when valid text is provided', function() {
        var tooltipText;
        tooltipText = 'blah';
        inject(function($rootScope, $compile) {
          scope = $rootScope.$new();
          element = angular.element("<span tooltip='" + tooltipText + "'>hello</span>");
          $compile(element)(scope);
          return scope.$digest();
        });
        return expect(element.find('.prettyTooltip').html()).toBe(tooltipText);
      });
      return it('should render no tooltip text when no valid text is provided', function() {
        inject(function($rootScope, $compile) {
          scope = $rootScope.$new();
          element = angular.element("<span tooltip>hello</span>");
          $compile(element)(scope);
          return scope.$digest();
        });
        return expect(element.find('.prettyTooltip').html()).toBe('');
      });
    });
  });

}).call(this);
