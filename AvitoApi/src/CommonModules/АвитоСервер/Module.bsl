#Область ПолучениеТокена
Функция ПолучитьТокен(Кабинет) Экспорт

	Если Не ЗначениеЗаполнено(Кабинет) Тогда
		Возврат Неопределено;
	КонецЕсли;

	Токен = ПолучитьТокенИзРегистра(Кабинет);
	
	Если Не ЗначениеЗаполнено(Токен) Тогда
		Токен = ПолучитьСтруктуруНовогоТокена(Кабинет);
		Если ЗначениеЗаполнено(Токен) Тогда
			ЗаписатьНовыйТокенВРегистр(Кабинет, Токен);
		КонецЕсли;
	КонецЕсли;
	Возврат Токен;
КонецФункции

Функция ПолучитьСтрокуПараметровДляПолученияТокена(Кабинет) Экспорт
	
	СтруктураПараметровКабинета = ПолучитьСтруктуруПараметровКабинета(Кабинет);
	СтрокаПараметров = "?grant_type=client_credentials";
	Для Каждого КлючЗначение Из СтруктураПараметровКабинета Цикл
		СтрокаПараметров = СтрокаПараметров + "&" + КлючЗначение.Ключ + "=" + КлючЗначение.Значение;
	КонецЦикла;

	Возврат СтрокаПараметров;

КонецФункции

Функция ПолучитьСтруктуруПараметровКабинета(Кабинет) Экспорт

	СтруктураВозврата = Новый Структура("client_id, client_secret");

	Запрос = Новый Запрос;
	Запрос.Текст = "ВЫБРАТЬ
				   |	КлиентИД как client_id,
				   |	КлиентСекрет как client_secret
				   |ИЗ
				   |	Справочник.Кабинеты
				   |ГДЕ
				   |	Ссылка = &Кабинет";

	Запрос.УстановитьПараметр("Кабинет", Кабинет);
	Выборка = Запрос.Выполнить().Выбрать();
	Выборка.Следующий();
	ЗаполнитьЗначенияСвойств(СтруктураВозврата, Выборка);
	Возврат СтруктураВозврата;

КонецФункции

Функция ПолучитьТокенИзРегистра(Кабинет) Экспорт

	Запрос = Новый Запрос;
	Запрос.Текст = "ВЫБРАТЬ
				   |	ТокеныКабинетов.Токен
				   |ИЗ
				   |	РегистрСведений.ТокеныКабинетов КАК ТокеныКабинетов
				   |ГДЕ
				   |	ТокеныКабинетов.Кабинет = &Кабинет
				   |	И ТокеныКабинетов.ДатаОкончанияДействия > &ТекущаяДата";
	Запрос.УстановитьПараметр("Кабинет", Кабинет);
	Запрос.УстановитьПараметр("ТекущаяДата", ТекущаяДата());
	Выборка = Запрос.Выполнить().Выбрать();
	Возврат ?(Выборка.Следующий(), Выборка.Токен, Неопределено);

КонецФункции

Функция ПолучитьСтруктуруНовогоТокена(Кабинет) Экспорт

	Хост = "api.avito.ru";
	Ресурс = "/token/" + ПолучитьСтрокуПараметровДляПолученияТокена(Кабинет);
	Возврат ОтправитьЗапрос(Хост, Ресурс, "GET")
	
КонецФункции

Процедура ЗаписатьНовыйТокенВРегистр(Кабинет, СтруктураНовогоТокена)

	НаборЗаписей = РегистрыСведений.ТокеныКабинетов.СоздатьНаборЗаписей();
	НаборЗаписей.Отбор.Кабинет.Установить(Кабинет);

	Строка = НаборЗаписей.Добавить();
	Строка.Кабинет = Кабинет;
	Строка.Токен = СтруктураНовогоТокена.access_token;
	Строка.ДатаОкончанияДействия = ТекущаяДата() + СтруктураНовогоТокена.expires_in;
	НаборЗаписей.Записать();

КонецПроцедуры

#КонецОбласти

Функция ИзменитьВебХук(Кабинет, ВебХукСсылка, Отключить) Экспорт
	
	Хост = "api.avito.ru";
	УРЛ = "/messenger/v2/webhook";
	Если Отключить Тогда
		УРЛ = УРЛ + "/unsubscribe";
	КонецЕсли;
	Заголовки = ПолучитьСтандартныеЗаголовкиАвито(Кабинет);
	Если Заголовки = Неопределено Тогда
		Возврат Ложь;
	КонецЕсли;
	
	ТелоЗапроса = ОбщегоНазначения.ПреобразоватьСтруктуруВJSON(Новый Структура("url", ВебхукСсылка));
	
	Результат = ОтправитьЗапрос(Хост, УРЛ, "POST", Заголовки, ТелоЗапроса);
	Если Результат <> Неопределено Тогда
		Возврат Результат.ok;
	Иначе
		Возврат Ложь;
	КонецЕсли;				
КонецФункции
	
Функция ОтправитьЗапрос(Хост, Ресурс, Метод, Заголовки = Неопределено, ТелоЗапроса = Неопределено)
	Если Заголовки = Неопределено Тогда
		Заголовки = Новый Соответствие();
	КонецЕсли;
	
	Соединение = Новый HTTPСоединение(Хост, , , , , , Новый ЗащищенноеСоединениеOpenSSL());
	Запрос = Новый HTTPЗапрос(Ресурс, Заголовки);
	Если Метод = "GET" Тогда
		Ответ = Соединение.Получить(Запрос);
	ИначеЕсли Метод = "POST" Тогда
		Если ТелоЗапроса <> Неопределено Тогда
			Запрос.УстановитьТелоИзСтроки(ТелоЗапроса);
		КонецЕсли;
		Ответ = Соединение.ОтправитьДляОбработки(Запрос);
	Иначе
		Сообщить("Метод не поддерживается");
		Возврат Неопределено;
	КонецЕсли;
	
	ТекстОтвета = Ответ.ПолучитьТелоКакСтроку();
	
	Если Ответ.КодСостояния = 200 Тогда
		Возврат ОбщегоНазначения.ПреобразоватьJSONВСтруктуру(ТекстОтвета);
	Иначе
		ЗаписьЖурналаРегистрации("Отправка запроса", УровеньЖурналаРегистрации.Ошибка, , ТекстОтвета);
		Возврат Неопределено;
	КонецЕсли;
КонецФункции

Функция ПолучитьТипСообщенияАвито(ТипСообщенияСтрока) Экспорт	
	Возврат ПолучитьСоответствиеТиповСообщенияАвито()[ТипСообщенияСтрока];
КонецФункции

Функция ПолучитьСоответствиеТиповСообщенияАвито() Экспорт
		
	СоответствиеТиповСообщений = Новый Соответствие();
	СоответствиеТиповСообщений.Вставить("text", Перечисления.ТипыСообщенийАвито.Текст);
	СоответствиеТиповСообщений.Вставить("image", Перечисления.ТипыСообщенийАвито.Изображение);
	СоответствиеТиповСообщений.Вставить("link", Перечисления.ТипыСообщенийАвито.Ссылка);
	СоответствиеТиповСообщений.Вставить("item", Перечисления.ТипыСообщенийАвито.Объявление);
	СоответствиеТиповСообщений.Вставить("location", Перечисления.ТипыСообщенийАвито.Локация);
	СоответствиеТиповСообщений.Вставить("call", Перечисления.ТипыСообщенийАвито.Звонок);
	
	Возврат СоответствиеТиповСообщений; 
КонецФункции

Функция ПолучитьДанныеУведомленияПоТипу(Данные, Тип) Экспорт
	
	Если Тип = Перечисления.ТипыСообщенийАвито.Текст Тогда
		Возврат Данные["text"];
	ИначеЕсли Тип = Перечисления.ТипыСообщенийАвито.Ссылка Тогда
		Возврат Данные["url"];
	ИначеЕсли Тип = Перечисления.ТипыСообщенийАвито.Объявление Тогда
		Возврат Данные["item_url"];
	ИначеЕсли Тип = Перечисления.ТипыСообщенийАвито.Локация Тогда
		Возврат "" + Данные["location"]["text"] + ". Координаты: " + Данные["location"]["lat"] + " " + Данные["location"]["lon"];
	ИначеЕсли Тип = Перечисления.ТипыСообщенийАвито.Звонок Тогда
		Возврат "Статус звонка " + Данные["status"] + "ИД Пользователя" + Данные["targeet_user_id"];
	ИначеЕсли Тип = Перечисления.ТипыСообщенийАвито.Изображение Тогда
		Возврат Данные["image"]["sizes"]["1280x960"]; 
	КонецЕсли;
	
КонецФункции

Функция ПолучитьБалансКошелька(Кабинет) Экспорт
	

	Хост = "api.avito.ru";
	УРЛ = СтрШаблон("/core/v1/accounts/%1/balance/", ПолучитьПерсональныйНомерКабинета(Кабинет));
	
	Заголовки = ПолучитьСтандартныеЗаголовкиАвито(Кабинет);
	Если Заголовки = Неопределено Тогда
		Возврат Ложь;
	КонецЕсли;
	
	Возврат ОтправитьЗапрос(Хост, УРЛ, "GET", Заголовки);
		
КонецФункции

Функция ПолучитьСтандартныеЗаголовкиАвито(Кабинет)
	
	ТокенКабинета = ПолучитьТокен(Кабинет);	
	Если НЕ ЗначениеЗаполнено(ТокенКабинета) Тогда
		Сообщить("Что-то пошло не так. Обратитесь в техническую поддержку!");
		Возврат Неопределено;
	КонецЕсли;
	Заголовки = Новый Соответствие;    
    Заголовки.Вставить("Authorization", "Bearer " + ТокенКабинета);
    Заголовки.Вставить("Content-Type", "application/json");
	
	Возврат Заголовки;
	
КонецФункции
	
Функция ПолучитьПерсональныйНомерКабинета(Кабинет) Экспорт
	
	Запрос = Новый Запрос;
	Запрос.Текст = "Выбрать ПерсональныйНомер из Справочник.Кабинеты где Ссылка = &Кабинет";
	Запрос.УстановитьПараметр("Кабинет", Кабинет);
	РЗ = Запрос.Выполнить().Выбрать();
	РЗ.Следующий();
	Возврат РЗ.ПерсональныйНомер;
	
КонецФункции

Функция ПолучитьИсториюОперацийЗаПериод(Кабинет, Период) Экспорт
	
	Если (Период.ДатаОкончания < Период.ДатаНачала) Тогда //по условиям нельзя больше чем за 7 дней статистику брать
		Сообщить("Дата начала не может быть больше даты окончания.");
		Возврат Неопределено;
	КонецЕсли;
	МассивПериодов = ПолучитьМассивПериодовПоНеделе(Период); 
	Хост = "api.avito.ru";
	УРЛ = "/core/v1/accounts/operations_history/";
	Заголовки = ПолучитьСтандартныеЗаголовкиАвито(Кабинет);
	Если Заголовки = Неопределено Тогда
		Возврат Ложь;
	КонецЕсли;
	ТаблицаОпераций = ИнициализироватьТаблицуОпераций();
	Для каждого СтруктураПериода из МассивПериодов Цикл
		ТелоЗапроса = ОбщегоНазначения.ПреобразоватьСтруктуруВJSON(Новый Структура("dateTimeFrom, dateTimeTo", СтруктураПериода.ДатаНачала, СтруктураПериода.ДатаОкончания));
		СтруктураОпераций = ОтправитьЗапрос(Хост, УРЛ, "POST", Заголовки, ТелоЗапроса);
		
		

		Для Каждого Стр Из СтруктураОпераций.result.operations Цикл
			НСтр = ТаблицаОпераций.Добавить();
			НСтр.Дата = XMLЗначение(Тип("Дата"), Стр.updatedat);
			НСтр.ТипОперации = Стр.operationType;
			НСтр.ИмяОперации = Стр.operationName;
			Если Стр.operationType <> "аванс" Тогда
				НСтр.ИмяСервиса = Стр.serviceName;
			КонецЕсли;
			
			НСтр.СтоимостьРубли = Стр.amountRub;
			НСтр.СтоимостьБонусы = Стр.amountBonus; 
		КонецЦикла;
		
	КонецЦикла;
	ТаблицаОпераций.Сортировать("Дата Возр");
	Возврат ТаблицаОпераций;		
КонецФункции

Функция ИнициализироватьТаблицуОпераций() Экспорт
	ТаблицаОпераций = Новый ТаблицаЗначений;
	ОписаниеСтрока = Новый ОписаниеТипов("Строка", , Новый КвалификаторыСтроки(150));
	ОписаниеЧисло = Новый ОписаниеТипов("Число");
	ТаблицаОпераций.Колонки.Добавить("Дата", Новый ОписаниеТипов("Дата"));
	ТаблицаОпераций.Колонки.Добавить("ТипОперации", ОписаниеСтрока);
	ТаблицаОпераций.Колонки.Добавить("ИмяСервиса", ОписаниеСтрока);
	ТаблицаОпераций.Колонки.Добавить("ИмяОперации", ОписаниеСтрока);
	ТаблицаОпераций.Колонки.Добавить("СтоимостьРубли", ОписаниеЧисло);
	ТаблицаОпераций.Колонки.Добавить("СтоимостьБонусы", ОписаниеЧисло);
	Возврат ТаблицаОпераций;
КонецФункции

Функция ПолучитьМассивПериодовПоНеделе(Период) Экспорт
	
	МассивПериодов = Новый Массив;
	ДатаНачала = Период.ДатаНачала;
	Неделя = 86400 * 6; 
	Пока ДатаНачала < Период.ДатаОкончания Цикл
		ДатаЧерезНеделю = ДатаНачала + Неделя;
		ДатаОкончания = ?(ДатаЧерезНеделю> Период.ДатаОкончания, Период.ДатаОкончания, ДатаЧерезНеделю);   
		СтруктураПериода = Новый Структура("ДатаНачала, ДатаОкончания", ДатаНачала, ДатаОкончания);
		МассивПериодов.Добавить(СтруктураПериода);
		ДатаНачала = ДатаЧерезНеделю + 86400;
	КонецЦикла;
	
	Возврат МассивПериодов
КонецФункции

