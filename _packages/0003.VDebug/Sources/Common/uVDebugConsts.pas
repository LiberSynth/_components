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

      '���������� �������� ���� String ��� ��������� ������. ��� ��������� � ������ ''d'' ' +
      '�������� ��������� ������������� ������ �� ������������� � ����������������� ���� ' +
      '�� ������� ������.';

{ TGUIDValueReplacer }

  SC_GUIDValueReplacer_Name =

      'TGUID value replacer for Delphi';

  SC_GUIDValueReplacer_Description =

      '���������� �������� ���� TGUID ��� ��������� ������. ��� ��������� � ������ ''d'' ' +
      '�������� ��������� ������������� GUID � ���� ������ ��� ��������� ��������������.';

implementation

end.
