
Elm.Native.Basics = {};
Elm.Native.Basics.make = function(elm) {
  elm.Native = elm.Native || {};
  elm.Native.Basics = elm.Native.Basics || {};
  if (elm.Native.Basics.values) return elm.Native.Basics.values;

  var JS = Elm.Native.JavaScript.make(elm);
  var Utils = Elm.Native.Utils.make(elm);

  function div(a, b) {
      return (a/b)|0;
  }
  function floatdiv(a, b) {
      return a / b;
  }
  function rem(a, b) {
      return a % b;
  }
  var mod = Utils.mod;
  function logBase(base, n) {
      return Math.log(n) / Math.log(base);
  }
  function add(a, b) {
      return a + b;
  }
  function sub(a, b) {
      return a - b;
  }
  function mul(a, b) {
      return a * b;
  }

  function min(a, b) {
      return Utils.cmp(a,b) < 0 ? a : b;
  }
  function max(a, b) {
      return Utils.cmp(a,b) > 0 ? a : b;
  }
  function clamp(lo, hi, n) {
      return Utils.cmp(n,lo) < 0 ? lo : Utils.cmp(n,hi) > 0 ? hi : n;
  }

  function eq(a, b) {
      return Utils.eq(a, b);
  }
  function neq(a, b) {
      return !eq(a, b);
  }
  function lt(a, b) {
      return Utils.cmp(a, b) < 0;
  }
  function gt(a, b) {
      return Utils.cmp(a, b) > 0;
  }
  function le(a, b) {
      return Utils.cmp(a, b) <= 0;
  }
  function ge(a, b) {
      return Utils.cmp(a, b) >= 0;
  }

  function xor(a, b) {
      return a !== b;
  }
  function not(b) {
      return !b;
  }
  function isInfinite(n) {
      return n === Infinity || n === -Infinity
  }

  function truncate(n) {
      return n|0;
  }

  function degrees(d) {
      return d * Math.PI / 180;
  }
  function turns(t) {
      return 2 * Math.PI * t;
  }
  function fromPolar(point) {
      var r = point._0;
      var t = point._1;
      return Utils.Tuple2(r * Math.cos(t), r * Math.sin(t));
  }
  function toPolar(point) {
      var x = point._0;
      var y = point._1;
      return Utils.Tuple2(Math.sqrt(x * x + y * y), Math.atan2(y,x));
  }

  var basics = {
      div: F2(div),
      floatdiv: F2(floatdiv),
      rem: F2(rem),
      mod: mod,
      add: F2(add),
      sub: F2(sub),
      mul: F2(mul),

      pi: Math.PI,
      e: Math.E,
      cos: Math.cos,
      sin: Math.sin,
      tan: Math.tan,
      acos: Math.acos,
      asin: Math.asin,
      atan: Math.atan,
      atan2: F2(Math.atan2),

      degrees:  degrees,
      turns:  turns,
      fromPolar:  fromPolar,
      toPolar:  toPolar,

      sqrt: Math.sqrt,
      logBase: F2(logBase),
      min: F2(min),
      max: F2(max),
      clamp: F3(clamp),
      compare: Utils.compare,

      eq: F2(eq),
      neq: F2(neq),
      lt: F2(lt),
      gt: F2(gt),
      le: F2(le),
      ge: F2(ge),

      xor: F2(xor),
      not: not,

      truncate: truncate,
      ceiling: Math.ceil,
      floor: Math.floor,
      round: Math.round,
      toFloat: function(x) { return x; },
      isNaN: isNaN,
      isInfinite: isInfinite
  };

  return elm.Native.Basics.values = basics;
};
