Функция ПреобразоватьJSONВСтруктуру(JSONСтрока, ВСоответствие = Ложь) Экспорт
	ЧтениеJSON = Новый ЧтениеJSON;
	ЧтениеJSON.УстановитьСтроку(JSONСтрока);

	Возврат ПрочитатьJSON(ЧтениеJSON, ВСоответствие);
КонецФункции

Функция ПреобразоватьСтруктуруВJSON(Структура) Экспорт
  
  ЗаписьJSON = Новый ЗаписьJSON();     
  ЗаписьJSON.УстановитьСтроку();
  ЗаписатьJSON(ЗаписьJSON, Структура);

  Возврат ЗаписьJSON.Закрыть();
  
КонецФункции

Функция ТаймСтэмпВДату(ТаймСтэмп) Экспорт
	Возврат Дата("19700101") + ТаймСтэмп;
КонецФункции
