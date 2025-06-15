/**
 * @file Golang text/template parser
 * @author Zachary Elliott <contact@zell.io>
 * @license BSD-3-Clause
 */

/// <reference types="tree-sitter-cli/dsl" />
// @ts-check

/// Int type defs

const PREC = {
  else_if_clause: 1,
  else_with_clause: 1,
  else_clause: 2,
};

const bin_digit = /[01]/;
const bin_digits = seq(bin_digit, repeat(seq(optional('_'), bin_digit)));
const bin_literal = seq('0', choice('b', 'B'), optional('_'), bin_digits);

const oct_digit = /[0-7]/;
const oct_digits = seq(oct_digit, repeat(seq(optional('_'), oct_digit)));
const oct_literal = seq('0', choice('o', 'O'), optional('_'), oct_digits);

const dec_digit = /[0-9]/;
const dec_digits = seq(dec_digit, repeat(seq(optional('_'), dec_digit)));
const dec_literal = choice('0', seq(/[1-9]/, optional(seq(optional('_'), dec_digits))));

const hex_digit = /[0-9a-fA-F]/;
const hex_digits = seq(hex_digit, repeat(seq(optional('_'), hex_digit)));
const hex_literal = seq('0', choice('x', 'X'), optional('_'), hex_digits);

const int_literal = choice(bin_literal, oct_literal, dec_literal, hex_literal);

/// Float type defs

const dec_exponent = seq(choice('e', 'E'), optional(choice('+', '-')), dec_digits);
const dec_float_literal = choice(
  seq(dec_digits, '.', optional(dec_digits), optional(dec_exponent)),
  seq(dec_digits, dec_exponent),
  seq('.', dec_digits, optional(dec_exponent))
);

const hex_exponent = seq(choice('p', 'P'), optional(choice('+', '-')), hex_digits);
const hex_mantissa = choice(
  seq(optional('_'), hex_digits, optional(seq('.', optional(hex_digits)))),
  seq('.', hex_digits),
);
const hex_float_literal = seq('0', choice('x', 'X'), hex_mantissa, hex_exponent);

const float_literal = choice(dec_float_literal, hex_float_literal);

/// Imaginary type defs

const imaginary_literal = seq(choice(dec_digits, int_literal, float_literal), 'i');

const identifier_regex = /[_\p{XID_Start}][_\p{XID_Continue}]*/;

const field_identifier_regex = /[[:upper:]][_\p{XID_Continue}]*/;
const field_regex = new RegExp(/[.]/.source + field_identifier_regex.source);

const key_identifier_regex = /[[:lower:]][_\p{XID_Continue}]*/;
const key_regex = new RegExp(/[.]/.source + key_identifier_regex.source);

module.exports = grammar({
  name: "gotmpl",

  word: $ => $.identifier,

  inline: $ => [
    $._if_pipeline,
    $._left_delimiter,
    $._pipeline_or_assignment,
    $._range_pipeline,
    $._right_delimiter,
    $._with_pipeline,
  ],

  conflicts: $ => [
    [$._else_clause],
    [$._else_if_clause],
    [$._else_with_clause],
  ],

  rules: {
    source_file: $ => repeat(
      $._segment,
    ),

    _segment: $ => choice(
      $.text,
      $._action,
    ),

    text: $ => prec.right(
      repeat1(
        choice(
          /[^{]+/,
          seq(token('{'), token.immediate(/[^{]/)),
        ),
      ),
    ),

    _action: $ => choice(
      $.statement,
      alias($._comment_statement, $.statement),
      $.if_action,
      $.range_action,
      $.block_action,
      $.define_action,
      $.with_action,
    ),

    statement: $ => seq(
      $._left_delimiter,
      choice(
        $.pipeline,
        'break',
        'continue',
        seq('template', $.string),
        seq('template', $.string, $._pipeline_or_assignment),
      ),
      $._right_delimiter,
    ),

    identifier: _ => /[_\p{XID_Start}][_\p{XID_Continue}]*/,

    _comment_statement: $ => seq(
      $._left_delimiter,
      $.comment,
      choice(token.immediate('}}'), token.immediate(' -}}')),
    ),

    comment: $ => seq(token.immediate('/*'), token(/[^*]*[*]+(?:[^/*][^*]*[*]+)*/), token('/')),

    pipeline: $ => $._pipeline,

    _pipeline: $ => choice(
      seq($._command, $._pipe, $._pipeline),
      $._command,
    ),

    _pipeline_or_assignment: $ => choice(
      $.pipeline,
      $.assignment,
    ),

    _else_statement: $ => seq($._left_delimiter, 'else', $._right_delimiter),

    _end_statement: $ => seq($._left_delimiter, 'end', $._right_delimiter),

    if_action: $ => seq(
      alias($._if_statement, $.statement),
      field('consequence', repeat($._segment)),
      repeat($._else_if_clause),
      optional($._else_clause),
      alias($._end_statement, $.statement),
    ),

    _if_statement: $ => seq($._left_delimiter, $._if_pipeline, $._right_delimiter),

    _if_pipeline: $ => seq('if', field('condition', $._pipeline_or_assignment)),

    _else_if_clause: $ => prec.dynamic(
      PREC.else_if_clause,
      seq(
        alias($._else_if_statement, $.statement),
        field('alternative', repeat($._segment)),
      ),
    ),

    _else_if_statement: $ => seq($._left_delimiter, 'else', $._if_pipeline, $._right_delimiter),

    _else_clause: $ => prec.dynamic(
      PREC.else_clause,
      seq(
        alias($._else_statement, $.statement),
        field('alternative', repeat($._segment)),
      ),
    ),

    range_action: $ => seq(
      alias($._range_statement, $.statement),
      field('body', repeat($._segment)),
      optional($._else_clause),
      alias($._end_statement, $.statement),
    ),

    _range_statement: $ => seq($._left_delimiter, $._range_pipeline, $._right_delimiter),

    _range_pipeline: $ => seq('range', $._pipeline_or_assignment),

    block_action: $ => seq(
      alias($._block_statement, $.statement),
      repeat($._segment),
      alias($._end_statement, $.statement),
    ),

    _block_statement: $ => seq($._left_delimiter, 'block', $.string, $._pipeline_or_assignment, $._right_delimiter),

    define_action: $ => seq(
      alias($._define_statement, $.statement),
      repeat($._segment),
      alias($._end_statement, $.statement),
    ),

    _define_statement: $ => seq($._left_delimiter, 'define', $.string, $._right_delimiter),

    with_action: $ => seq(
      alias($._with_statement, $.statement),
      field('consequence', repeat($._segment)),
      repeat($._else_with_clause),
      optional($._else_clause),
      alias($._end_statement, $.statement),
    ),

    _with_statement: $ => seq($._left_delimiter, $._with_pipeline, $._right_delimiter),

    _with_pipeline: $ => seq('with', $._pipeline_or_assignment),

    _else_with_clause: $ => prec.dynamic(
      PREC.else_with_clause,
      seq(
        alias($._else_with_statement, $.statement),
        field('alternative', repeat($._segment)),
      ),
    ),

    _else_with_statement: $ => seq($._left_delimiter, 'else', $._with_pipeline, $._right_delimiter),

    _command: $ => choice(
      $.argument,
      $.method_call,
      $.function_call,
    ),

    argument: $ => choice(
      $._literal,
      $.nil,
      $.dot,
      $.variable,
      $.field,
      $.key,
      $.selector_expression,
      $.parenthesized,
    ),

    method_call: $ => seq(
      field('method',
        choice(
          $.field,
          $.selector_expression,
        ),
      ),
      field('argument', repeat1($.argument))
    ),

    function_call: $ => seq(
      field('function', choice($.builtin, $.identifier)),
      field('argument', repeat($.argument)),
    ),

    builtin: $ => choice(
      'and',
      'call',
      'html',
      'index',
      'slice',
      'js',
      'len',
      'not',
      'or',
      'printf',
      'println',
      'urlquery',
      'eq',
      'ne',
      'lt',
      'le',
      'gt',
      'ge',
    ),

    _literal: $ => choice(
      $.boolean,
      $.string,
      $.rune,
      $.integer,
      $.float,
      $.imaginary,
    ),

    boolean: _ => choice('true', 'false'),

    string: $ => choice($._raw_string, $._interpreted_string),

    _raw_string: _ => seq('`', /[^`]*/, '`'),

    _interpreted_string: $ => seq('"', repeat(choice(/[^"\n\\]+/, $.escape_sequence)), token.immediate('"')),

    escape_sequence: _ => token.immediate(
      seq('\\', choice(
        /[^xuU]/,
        /\d{2,3}/,
        /x[0-9a-fA-F]{2,}/,
        /u[0-9a-fA-F]{4}/,
        /U[0-9a-fA-F]{8}/,
      ))
    ),

    rune: _ => token(seq(
      "'",
      choice(
        /[^'\\]/,
        seq(
          '\\',
          choice(
            seq('x', hex_digit, hex_digit),
            seq(oct_digit, oct_digit, oct_digit),
            seq('u', hex_digit, hex_digit, hex_digit, hex_digit),
            seq('U', hex_digit, hex_digit, hex_digit, hex_digit, hex_digit, hex_digit, hex_digit, hex_digit),
            seq(choice('a', 'b', 'f', 'n', 'r', 't', 'v', '\\', "'", '"')),
          ),
        ),
      ),
      "'",
    )),

    integer: _ => token(int_literal),

    float: _ =>  token(float_literal),

    imaginary: _ => token(imaginary_literal),

    nil: _ => 'nil',

    dot: _ => '.',

    variable: $ => seq(
      '$',
      alias(
        token.immediate(/[[:alnum:]]*/),
        $.identifier,
      ),
    ),

    assignment: $ => seq(
      field('left', $.variable),
      field('operator', choice(':=', '=')),
      field('right', $.pipeline),
    ),

    field: $ => seq('.', $._field_identifier),

    _field_identifier: $ => alias(token.immediate(field_identifier_regex), $.identifier),

    key: $ => seq('.', $._key_identifier),

    _key_identifier: $ => alias(token.immediate(key_identifier_regex), $.identifier),

   selector_expression: $ => seq(
      field('operand', choice(
        $.field,
        $.key,
        $.variable,
        $.parenthesized,
        $.selector_expression,
      )),
      field('selector', choice(
          alias(seq(alias(token.immediate('.'), '.'), $._field_identifier), $.field),
          alias(seq(alias(token.immediate('.'), '.'), $._key_identifier), $.key),
      )),
    ),

    parenthesized: $ => seq("(", $.pipeline, ")"),

    _left_delimiter: _ => choice(token('{{'), token('{{- ')),

    _right_delimiter: _ => choice(token('}}'), token(' -}}')),

    _pipe: _ => '|',
  }
});
