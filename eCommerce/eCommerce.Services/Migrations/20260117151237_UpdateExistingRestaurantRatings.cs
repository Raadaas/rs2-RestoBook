using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace eCommerce.Services.Migrations
{
    /// <inheritdoc />
    public partial class UpdateExistingRestaurantRatings : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            // Update AverageRating and TotalReviews for all restaurants based on existing reviews
            migrationBuilder.Sql(@"
                UPDATE r
                SET 
                    r.AverageRating = ISNULL(reviewStats.AvgRating, 0),
                    r.TotalReviews = ISNULL(reviewStats.ReviewCount, 0)
                FROM Restaurants r
                LEFT JOIN (
                    SELECT 
                        RestaurantId,
                        AVG(CAST(Rating AS DECIMAL(3,2))) AS AvgRating,
                        COUNT(*) AS ReviewCount
                    FROM Reviews
                    GROUP BY RestaurantId
                ) reviewStats ON r.Id = reviewStats.RestaurantId;
            ");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {

        }
    }
}
