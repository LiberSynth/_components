unit uSomeParams;

{ TODO -oVasilyevSM -cTParams: Режим "сохранять строки всегда в кавычках }
{ TODO -oVasilyevSM -cuParams: Нужна оболочка TFileParams, которая будет сохраняться в файл. Вот она-то и должна поддерживать комментарии итд. }
{ TODO -oVasilyevSM -cuParams: Режим TFileParams.AutoSave. В каждом SetAs вызывать в нем SaveTo... Куда to - выставлять еще одним свойством или комбайном None, ToFile, ToStream }
{ TODO -oVasilyevSM -cuParams: Компонент TRegParams }
{ TODO -oVasilyevSM -cuParams: Чтение с событием для прогресса. В Вордстоке словарь читается прилично времени. }
{ TODO -oVasilyevSM -cuParams: Для работы с мультистроковыми параметрами нужно какое-то удобное средство. GetList или как табличные записи. Сейчас ParamByName вернет первый из списка и все.  }

interface

implementation

end.
