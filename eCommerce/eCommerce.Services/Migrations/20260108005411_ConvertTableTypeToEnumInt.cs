using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace eCommerce.Services.Migrations
{
    /// <inheritdoc />
    public partial class ConvertTableTypeToEnumInt : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            // Convert TableType column from string to int (enum storage)
            // First, create a temporary int column
            migrationBuilder.AddColumn<int>(
                name: "TableType_New",
                table: "Tables",
                type: "int",
                nullable: true);

            // Convert existing string values to enum int values
            migrationBuilder.Sql(@"
                UPDATE [Tables]
                SET [TableType_New] = 
                    CASE 
                        WHEN TRY_CAST([TableType] AS INT) IS NOT NULL THEN CAST([TableType] AS INT)
                        WHEN [TableType] = 'Circle' THEN 1
                        WHEN [TableType] = 'Square' THEN 2
                        WHEN [TableType] = 'Rectangle' THEN 3
                        ELSE NULL
                    END
                WHERE [TableType] IS NOT NULL
            ");

            // Drop old column
            migrationBuilder.DropColumn(
                name: "TableType",
                table: "Tables");

            // Rename new column to TableType
            migrationBuilder.RenameColumn(
                name: "TableType_New",
                table: "Tables",
                newName: "TableType");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            // Convert back from int to string
            // Create temporary string column
            migrationBuilder.AddColumn<string>(
                name: "TableType_Old",
                table: "Tables",
                type: "nvarchar(50)",
                maxLength: 50,
                nullable: true);

            // Convert enum values back to string
            migrationBuilder.Sql(@"
                UPDATE [Tables]
                SET [TableType_Old] = 
                    CASE 
                        WHEN [TableType] = 1 THEN 'Circle'
                        WHEN [TableType] = 2 THEN 'Square'
                        WHEN [TableType] = 3 THEN 'Rectangle'
                        ELSE NULL
                    END
                WHERE [TableType] IS NOT NULL
            ");

            // Drop int column
            migrationBuilder.DropColumn(
                name: "TableType",
                table: "Tables");

            // Rename temporary column back to TableType
            migrationBuilder.RenameColumn(
                name: "TableType_Old",
                table: "Tables",
                newName: "TableType");
        }
    }
}
