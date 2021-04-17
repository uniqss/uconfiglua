#include "uniqs_xlsx_reader.h"

#include <OpenXLSX.hpp>
#include <iostream>
#include <numeric>
#include <random>

using namespace std;
using namespace OpenXLSX;

char __transCellType(const OpenXLSX::XLValueType& vt)
{
	// Empty, Boolean, Integer, Float, Error, String
	static char type[] = { 'N', 'B', 'I', 'F', 'E', 'S' };
	return type[(int)vt];
}

void __getCellValueString(OpenXLSX::XLCellValue& cellValue, std::string& str)
{
	switch (cellValue.valueType())
	{
	case XLValueType::String:
		str = cellValue.get<std::string>();
		break;
	case XLValueType::Integer:
		str = std::to_string(cellValue.get<int64_t>());
		break;
	case XLValueType::Empty:
		str = "";
		break;
	case XLValueType::Float:
		str = std::to_string(cellValue.get<double>());
		break;
	default:
		str = "";
		break;
	}
}

int read_xlsx(
	const char* filename
	, std::vector<std::pair<std::string, std::vector<std::vector<std::string> > > >& vecResult
	, int maxRows
	, int maxCols
)
{
	XLDocument doc;
	OpenXLSX::XLWorksheet wks;

	std::string filaNameStr = filename;

	vecResult.clear();

	uint32_t rowIdxMax = maxRows;
	if (maxRows <= 0)
	{
		rowIdxMax = std::numeric_limits<unsigned>::max();
	}
	uint32_t colIdxMax = maxCols;
	if (maxCols <= 0)
	{
		colIdxMax = std::numeric_limits<unsigned>::max();
	}

	doc.open(filaNameStr);
	auto wbk = doc.workbook();
	const std::vector<std::string>& sheetNames = wbk.worksheetNames();

	doc.close();

	return 0;
}
int read_xlsx(
	const std::string& filename
	, std::vector<std::pair<std::string, std::vector<std::vector<std::string> > > >& vecResult
	, int maxRows
	, int maxCols
)
{
	return read_xlsx(filename.c_str(), vecResult);
}
