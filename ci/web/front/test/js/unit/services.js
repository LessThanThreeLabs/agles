// Generated by IcedCoffeeScript 1.3.3e
(function() {
  'use strict';

  describe('Koality services', function() {
    describe('initial state', function() {
      it('should have non-null values', function() {
        var csrfToken, email, fileSuffix, firstName, lastName, userId;
        fileSuffix = '_d487ab5e';
        csrfToken = '4ed9a4a31had';
        userId = 17;
        email = 'email@address.com';
        firstName = 'First';
        lastName = 'Last';
        module('koality.service', function($provide) {
          var mockedWindow;
          mockedWindow = {
            fileSuffix: fileSuffix,
            csrfToken: csrfToken,
            accountInformation: {
              id: userId,
              email: email,
              firstName: firstName,
              lastName: lastName
            }
          };
          $provide.value('$window', mockedWindow);
        });
        return inject(function(initialState) {
          expect(initialState.fileSuffix).toBe(fileSuffix);
          expect(initialState.csrfToken).toBe(csrfToken);
          expect(initialState.user.id).toBe(userId);
          expect(initialState.user.email).toBe(email);
          expect(initialState.user.firstName).toBe(firstName);
          return expect(initialState.user.lastName).toBe(lastName);
        });
      });
      it('should have null values', function() {
        module('koality.service', function($provide) {
          var mockedWindow;
          mockedWindow = {
            fileSuffix: '',
            csrfToken: '',
            accountInformation: {
              id: '',
              email: '',
              firstName: '',
              lastName: ''
            }
          };
          $provide.value('$window', mockedWindow);
        });
        return inject(function(initialState) {
          expect(initialState.fileSuffix).toBeNull();
          expect(initialState.csrfToken).toBeNull();
          expect(initialState.user.id).toBeNull();
          expect(initialState.user.email).toBeNull();
          expect(initialState.user.firstName).toBeNull();
          return expect(initialState.user.lastName).toBeNull();
        });
      });
      return it('should not allow edits', function() {
        module('koality.service');
        return inject(function(initialState) {
          var addValueToInitialState, removeValueFromInitialState;
          addValueToInitialState = function() {
            return initialState.blah = 'blah';
          };
          removeValueFromInitialState = function() {
            return delete initialState.user;
          };
          expect(addValueToInitialState).toThrow();
          return expect(removeValueFromInitialState).toThrow();
        });
      });
    });
    describe('file suffix adder', function() {
      var fileSuffix;
      fileSuffix = '_hc8oeb1f';
      beforeEach(function() {
        return module('koality.service', function($provide) {
          var mockedInitialState;
          mockedInitialState = {
            fileSuffix: fileSuffix
          };
          $provide.value('initialState', mockedInitialState);
        });
      });
      it('should properly add the correct file suffix for valid file urls', function() {
        return inject(function(fileSuffixAdder) {
          expect(fileSuffixAdder.addFileSuffix('a.gif')).toBe("a" + fileSuffix + ".gif");
          expect(fileSuffixAdder.addFileSuffix('/img/a.png')).toBe("/img/a" + fileSuffix + ".png");
          expect(fileSuffixAdder.addFileSuffix('/short.html')).toBe("/short" + fileSuffix + ".html");
          return expect(fileSuffixAdder.addFileSuffix('/img/longerName.fakeExtension')).toBe("/img/longerName" + fileSuffix + ".fakeExtension");
        });
      });
      return it('should fail to add the correct file suffix for invalid file urls', function() {
        return inject(function(fileSuffixAdder) {
          expect(fileSuffixAdder.addFileSuffix('agif')).toBe('agif');
          expect(fileSuffixAdder.addFileSuffix('/img/apng')).toBe('/img/apng');
          expect(fileSuffixAdder.addFileSuffix('/shorthtml')).toBe('/shorthtml');
          return expect(fileSuffixAdder.addFileSuffix('/img/longerNamefakeExtension')).toBe('/img/longerNamefakeExtension');
        });
      });
    });
    describe('integer converter', function() {
      beforeEach(module('koality.service'));
      it('should return integeres given integers', function() {
        return inject(function(integerConverter) {
          expect(integerConverter.toInteger(5)).toBe(5);
          expect(integerConverter.toInteger(-1)).toBe(-1);
          return expect(integerConverter.toInteger(9001)).toBe(9001);
        });
      });
      it('should return null given floats', function() {
        return inject(function(integerConverter) {
          expect(integerConverter.toInteger(5.1)).toBeNull();
          expect(integerConverter.toInteger(-1.7)).toBeNull();
          return expect(integerConverter.toInteger(9001.1238907)).toBeNull();
        });
      });
      it('should return numbers given valid strings', function() {
        return inject(function(integerConverter) {
          return expect(typeof integerConverter.toInteger('5')).toBe('number');
        });
      });
      it('should properly parse valid integers', function() {
        return inject(function(integerConverter) {
          expect(integerConverter.toInteger('5')).toBe(5);
          expect(integerConverter.toInteger('-1')).toBe(-1);
          return expect(integerConverter.toInteger('123456789')).toBe(123456789);
        });
      });
      return it('should return null for invalid integers', function() {
        return inject(function(integerConverter) {
          expect(integerConverter.toInteger('')).toBeNull();
          expect(integerConverter.toInteger(null)).toBeNull();
          expect(integerConverter.toInteger(void 0)).toBeNull();
          expect(integerConverter.toInteger('1.3')).toBeNull();
          return expect(integerConverter.toInteger('five')).toBeNull();
        });
      });
    });
    describe('ansiparse service', function() {
      beforeEach(module('koality.service'));
      it('should wrap plaintext in default styling', function() {
        return inject(function(ansiparse) {
          return expect(ansiparse.parse('thisIsATest')).toBe('<span class="ansi"><span class="foregroundDefault backgroundDefault">thisIsATest</span></span>');
        });
      });
      it('should escape spaces', function() {
        return inject(function(ansiparse) {
          return expect(ansiparse.parse('this is  A   test')).toBe('<span class="ansi"><span class="foregroundDefault backgroundDefault">this&nbsp;is&nbsp;&nbsp;A&nbsp;&nbsp;&nbsp;test</span></span>');
        });
      });
      it('should handle changing columns', function() {
        return inject(function(ansiparse) {
          expect(ansiparse.parse('one\x1b[5Gtwo')).toBe('<span class="ansi"><span class="foregroundDefault backgroundDefault">one&nbsp;&nbsp;two</span></span>');
          return expect(ansiparse.parse('one\x1b[0Gtwo')).toBe('<span class="ansi"><span class="foregroundDefault backgroundDefault">two</span></span>');
        });
      });
      it('should handle colors, bold, and clearing', function() {
        return inject(function(ansiparse) {
          return expect(ansiparse.parse('\x1b[33;45;1mbright yellow on magenta, \x1b[0mdefault')).toBe('<span class="ansi"><span class="foregroundYellow backgroundMagenta bright">bright&nbsp;yellow&nbsp;on&nbsp;magenta,&nbsp;</span>' + '<span class="foregroundDefault backgroundDefault">default</span></span>');
        });
      });
      it('should persist colors and bold through other styles', function() {
        return inject(function(ansiparse) {
          return expect(ansiparse.parse('default, \x1b[31;1mbright red, \x1b[34;46mbright blue on cyan, \x1b[22mblue on cyan')).toBe('<span class="ansi"><span class="foregroundDefault backgroundDefault">default,&nbsp;</span>' + '<span class="foregroundRed backgroundDefault bright">bright&nbsp;red,&nbsp;</span>' + '<span class="foregroundBlue backgroundCyan bright">bright&nbsp;blue&nbsp;on&nbsp;cyan,&nbsp;</span>' + '<span class="foregroundBlue backgroundCyan">blue&nbsp;on&nbsp;cyan</span></span>');
        });
      });
      it('should overwrite old characters with new styles', function() {
        return inject(function(ansiparse) {
          return expect(ansiparse.parse('plain\x1b[0G\x1b[32mgreen')).toBe('<span class="ansi"><span class="foregroundGreen backgroundDefault">green</span></span>');
        });
      });
      it('should handle carriage returns', function() {
        return inject(function(ansiparse) {
          return expect(ansiparse.parse('123456789\r9876')).toBe('<span class="ansi"><span class="foregroundDefault backgroundDefault">987656789</span></span>');
        });
      });
      return it('should escape dangerous characters', function() {
        return inject(function(ansiparse) {
          return expect(ansiparse.parse('&<>"\'/')).toBe('<span class="ansi"><span class="foregroundDefault backgroundDefault">&amp;&lt;&gt;&quot;&#39;&#x2F;</span></span>');
        });
      });
    });
    describe('rpc', function() {
      var mockedSocket;
      mockedSocket = null;
      beforeEach(function() {
        jasmine.Clock.useMock();
        mockedSocket = {
          makeRequest: jasmine.createSpy('makeRequest').andCallFake(function(resource, requestType, methodName, data, callback) {
            return setTimeout((function() {
              if (callback != null) return callback(null, 'ok');
            }), 100);
          })
        };
        return module('koality.service', function($provide) {
          $provide.value('socket', mockedSocket);
        });
      });
      it('should properly call socket when making rpc requests', function() {
        return inject(function(rpc) {
          rpc.makeRequest('users', 'update', 'login', {
            id: 9001
          });
          expect(mockedSocket.makeRequest).toHaveBeenCalled();
          expect(mockedSocket.makeRequest.callCount).toBe(1);
          rpc.makeRequest('users', 'update', 'logout', {
            id: 9001
          });
          expect(mockedSocket.makeRequest).toHaveBeenCalled();
          return expect(mockedSocket.makeRequest.callCount).toBe(2);
        });
      });
      return it('should have callback called after some delay', function() {
        return inject(function(rpc) {
          var fakeCallback;
          fakeCallback = jasmine.createSpy('fakeCallback');
          rpc.makeRequest('users', 'update', 'login', {
            id: 9001
          }, fakeCallback);
          expect(mockedSocket.makeRequest).toHaveBeenCalled();
          expect(mockedSocket.makeRequest.callCount).toBe(1);
          expect(fakeCallback).not.toHaveBeenCalled();
          jasmine.Clock.tick(101);
          return expect(fakeCallback).toHaveBeenCalled();
        });
      });
    });
    describe('events', function() {
      it('should request to listen on eventName given from the socket', function() {
        var eventToFireOn, mockedSocket;
        eventToFireOn = 'aeoutnhuaensuha';
        mockedSocket = {
          makeRequest: jasmine.createSpy('makeRequest').andCallFake(function(resource, requestType, methodName, data, callback) {
            return callback(null, eventToFireOn);
          }),
          respondTo: jasmine.createSpy('respondTo')
        };
        module('koality.service', function($provide) {
          $provide.value('socket', mockedSocket);
        });
        return inject(function(events) {
          var fakeCallback;
          fakeCallback = function() {};
          events.listen('users', 'basic information', 9001).setCallback(fakeCallback).subscribe();
          expect(mockedSocket.respondTo.mostRecentCall.args[0]).toBe(eventToFireOn);
          expect(mockedSocket.makeRequest.callCount).toBe(1);
          return expect(mockedSocket.respondTo.callCount).toBe(1);
        });
      });
      return it('should handle subscribe and unsubscribe', function() {
        var eventToFireOn, interval, mockedSocket;
        jasmine.Clock.useMock();
        interval = null;
        eventToFireOn = 'aeoutnhuaensuha';
        mockedSocket = {
          makeRequest: jasmine.createSpy('makeRequest').andCallFake(function(resource, requestType, methodName, data, callback) {
            if (requestType === 'subscribe') callback(null, eventToFireOn);
            if (requestType === 'unsubscribe') return clearInterval(interval);
          }),
          respondTo: jasmine.createSpy('respondTo').andCallFake(function(eventName, callback) {
            assert.ok(eventName === eventToFireOn);
            return interval = setInterval((function() {
              return callback('hello');
            }), 100);
          })
        };
        module('koality.service', function($provide) {
          $provide.value('socket', mockedSocket);
        });
        return inject(function(events) {
          var fakeCallback, fakeEvents;
          fakeCallback = jasmine.createSpy('fakeCallback');
          fakeEvents = events.listen('users', 'basic information', 9001).setCallback(fakeCallback).subscribe();
          expect(fakeCallback.callCount).toBe(0);
          jasmine.Clock.tick(101);
          expect(fakeCallback.callCount).toBe(1);
          jasmine.Clock.tick(100);
          expect(fakeCallback.callCount).toBe(2);
          fakeEvents.unsubscribe();
          jasmine.Clock.tick(500);
          return expect(fakeCallback.callCount).toBe(2);
        });
      });
    });
    return describe('changes rpc', function() {
      beforeEach(function() {
        var mockedRpc, numChanges;
        numChanges = 107;
        mockedRpc = {
          makeRequest: function(resource, requestType, methodName, data, callback) {
            var endIndex, num;
            endIndex = Math.min(numChanges, data.startIndex + 100);
            return callback(null, (function() {
              var _i, _ref, _results;
              _results = [];
              for (num = _i = _ref = data.startIndex; _ref <= endIndex ? _i < endIndex : _i > endIndex; num = _ref <= endIndex ? ++_i : --_i) {
                _results.push(num);
              }
              return _results;
            })());
          }
        };
        return module('koality.service', function($provide) {
          $provide.value('rpc', mockedRpc);
        });
      });
      it('should receive changes', function() {
        return inject(function(changesRpc) {
          var fakeCallback;
          fakeCallback = jasmine.createSpy('fakeCallback');
          changesRpc.queueRequest(17, 'all', null, 0, fakeCallback);
          expect(fakeCallback.callCount).toBe(1);
          return expect(fakeCallback.mostRecentCall.args[1].length).toBe(100);
        });
      });
      return it('should stop receiving changes if no more to receive', function() {
        return inject(function(changesRpc) {
          var fakeCallback;
          fakeCallback = jasmine.createSpy('fakeCallback');
          changesRpc.queueRequest(17, 'all', null, 0, fakeCallback);
          expect(fakeCallback.callCount).toBe(1);
          expect(fakeCallback.mostRecentCall.args[1].length).toBe(100);
          changesRpc.queueRequest(17, 'all', null, 100, fakeCallback);
          expect(fakeCallback.callCount).toBe(2);
          expect(fakeCallback.mostRecentCall.args[1].length).toBe(7);
          changesRpc.queueRequest(17, 'all', null, 107, fakeCallback);
          expect(fakeCallback.callCount).toBe(2);
          changesRpc.queueRequest(17, 'all', null, 0, fakeCallback);
          expect(fakeCallback.callCount).toBe(3);
          return expect(fakeCallback.mostRecentCall.args[1].length).toBe(100);
        });
      });
    });
  });

}).call(this);
