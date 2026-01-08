using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace eCommerce.Services.Migrations
{
    /// <inheritdoc />
    public partial class ChangeTableTypeToEnum : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Tables_TableTypes_TableTypeId",
                table: "Tables");

            migrationBuilder.DropTable(
                name: "TableTypes");

            migrationBuilder.DropIndex(
                name: "IX_Tables_TableTypeId",
                table: "Tables");

            migrationBuilder.RenameColumn(
                name: "TableTypeId",
                table: "Tables",
                newName: "TableType");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.RenameColumn(
                name: "TableType",
                table: "Tables",
                newName: "TableTypeId");

            migrationBuilder.CreateTable(
                name: "TableTypes",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    Description = table.Column<string>(type: "nvarchar(200)", maxLength: 200, nullable: true),
                    IsActive = table.Column<bool>(type: "bit", nullable: false),
                    Name = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_TableTypes", x => x.Id);
                });

            migrationBuilder.CreateIndex(
                name: "IX_Tables_TableTypeId",
                table: "Tables",
                column: "TableTypeId");

            migrationBuilder.CreateIndex(
                name: "IX_TableTypes_Name",
                table: "TableTypes",
                column: "Name",
                unique: true);

            migrationBuilder.AddForeignKey(
                name: "FK_Tables_TableTypes_TableTypeId",
                table: "Tables",
                column: "TableTypeId",
                principalTable: "TableTypes",
                principalColumn: "Id",
                onDelete: ReferentialAction.SetNull);
        }
    }
}
