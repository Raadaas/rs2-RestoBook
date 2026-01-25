using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace eCommerce.Services.Migrations
{
    /// <inheritdoc />
    public partial class ConvertReservationStatusToEnum : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            // First, add a temporary State column as int
            migrationBuilder.AddColumn<int>(
                name: "State",
                table: "Reservations",
                type: "int",
                nullable: false,
                defaultValue: 0); // Default to Requested (0)

            // Convert existing string Status values to enum State values
            // Requested = 0, Confirmed = 1, Completed = 2, Cancelled = 3
            migrationBuilder.Sql(@"
                UPDATE Reservations
                SET State = CASE
                    WHEN Status = 'Pending' OR Status = 'Requested' THEN 0  -- Requested
                    WHEN Status = 'Confirmed' THEN 1  -- Confirmed
                    WHEN Status = 'Completed' THEN 2  -- Completed
                    WHEN Status = 'Cancelled' THEN 3  -- Cancelled
                    ELSE 0  -- Default to Requested for unknown values
                END
            ");

            // Drop the old Status column
            migrationBuilder.DropColumn(
                name: "Status",
                table: "Reservations");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            // Add back the Status column as string
            migrationBuilder.AddColumn<string>(
                name: "Status",
                table: "Reservations",
                type: "nvarchar(20)",
                maxLength: 20,
                nullable: false,
                defaultValue: "Pending");

            // Convert enum State values back to string Status values
            migrationBuilder.Sql(@"
                UPDATE Reservations
                SET Status = CASE
                    WHEN State = 0 THEN 'Pending'  -- Requested -> Pending (backward compatibility)
                    WHEN State = 1 THEN 'Confirmed'  -- Confirmed
                    WHEN State = 2 THEN 'Completed'  -- Completed
                    WHEN State = 3 THEN 'Cancelled'  -- Cancelled
                    ELSE 'Pending'  -- Default
                END
            ");

            // Drop the State column
            migrationBuilder.DropColumn(
                name: "State",
                table: "Reservations");
        }
    }
}
