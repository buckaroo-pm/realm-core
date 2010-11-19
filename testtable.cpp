#include "tightdb.h"
#include <UnitTest++.h>

TEST(Table1) {
	Table table("table1");
	table.RegisterColumn("first");
	table.RegisterColumn("second");

	const size_t ndx = table.AddRow();
	table.Set(0, ndx, 0);
	table.Set(1, ndx, 10);

	CHECK_EQUAL(0, table.Get(0, ndx));
	CHECK_EQUAL(10, table.Get(1, ndx));
}

enum Days {
	Mon,
	Tue,
	Wed,
	Thu,
	Fri,
	Sat,
	Sun
};

TDB_TABLE_4(TestTable,
			Int,        first,
			Int,        second,
			Bool,       third,
			Enum<Days>, fourth)

TEST(Table2) {
	TestTable table;

	TestTable::Cursor r = table.Add(0, 10, true, Wed);

	CHECK_EQUAL(0, r.first);
	CHECK_EQUAL(10, r.second);
	CHECK_EQUAL(true, r.third);
	CHECK_EQUAL(Wed, r.fourth);
}

TEST(Table3) {
	TestTable table;

	for (size_t i = 0; i < 100; ++i) {
		table.Add(0, 10, true, Wed);
	}

	CHECK_EQUAL(0, table.first.Find(0));
	CHECK_EQUAL(-1, table.first.Find(1));
	CHECK_EQUAL(0, table.second.Find(10));
	CHECK_EQUAL(-1, table.second.Find(100));
	CHECK_EQUAL(0, table.third.Find(true));
	CHECK_EQUAL(-1, table.third.Find(false));
	CHECK_EQUAL(0, table.fourth.Find(Wed));
	CHECK_EQUAL(-1, table.fourth.Find(Mon));
}

TDB_TABLE_2(TestTableEnum,
			Enum<Days>, first,
			Int, second)

TEST(Table4) {
	TestTableEnum table;

	TestTableEnum::Cursor r = table.Add(Mon, 120);

	CHECK_EQUAL(Mon, r.first);
	CHECK_EQUAL(120, r.second);
}

