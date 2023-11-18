unit uVDebugConsts;

interface

const

  SC_ExpressionKey_VDP = 'd';

  SC_ExceptionFormat = '%s: %s';
  SC_ErrorFormat     = 'Error: %s';
  SC_WrapperFormat   = '%s (%s)';

  SC_EvaluatorNotAssigned = 'Evaluator not assigned';
  SC_FormCaption          = '%s for %s';
  IC_MaxHistoryCount      = 30;

{ TStringValueReplacer }

  SC_StringValueReplacer_Name =

      'String value replacer for Delphi';

  SC_StringValueReplacer_Description =

      'Заменитель значения типа String для отладчика Дельфи. Для выражения с ключом ''d'' ' +
      'заменяет дефолтное представление строки со спецсимволами в шестнадцатеричном виде ' +
      'на обычную строку.';

{ TGUIDValueReplacer }

  SC_GUIDValueReplacer_Name =

      'TGUID value replacer for Delphi';

  SC_GUIDValueReplacer_Description =

      'Заменитель значения типа TGUID для отладчика Дельфи. Для выражения с ключом ''d'' ' +
      'заменяет дефолтное представление GUID в виде записи его строковым представлением.';

implementation

end.
