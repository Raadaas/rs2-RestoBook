using eCommerce.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using eCommerce.Services.Database;

namespace eCommerce.WebAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    public class AnalyticsController : ControllerBase
    {
        private readonly eCommerceDbContext _context;

        public AnalyticsController(eCommerceDbContext context)
        {
            _context = context;
        }

        [HttpGet("hourly")]
        public async Task<ActionResult<List<object>>> GetHourlyOccupancy([FromQuery] int? restaurantId = null)
        {
            if (!restaurantId.HasValue)
            {
                return BadRequest("restaurantId is required");
            }

            // Get restaurant to get working hours
            var restaurant = await _context.Restaurants
                .FirstOrDefaultAsync(r => r.Id == restaurantId.Value);

            if (restaurant == null)
            {
                return NotFound("Restaurant not found");
            }

            // Get all reservations for this restaurant (non-cancelled)
            var reservations = await _context.Reservations
                .Where(r => r.RestaurantId == restaurantId.Value &&
                           r.Status != "Cancelled" &&
                           r.CancelledAt == null)
                .ToListAsync();

            // Get restaurant working hours
            var openHour = restaurant.OpenTime.Hours;
            var closeHour = restaurant.CloseTime.Hours;
            
            // Handle case where close time is next day (e.g., 22:00 to 02:00)
            if (closeHour < openHour)
            {
                closeHour += 24; // Add 24 hours for next day
            }

            // Initialize hours based on restaurant working hours
            var hourlyData = new List<object>();
            for (int hour = openHour; hour <= closeHour; hour++)
            {
                var displayHour = hour % 24; // Convert back to 0-23 range for display
                
                // Calculate the hour interval [hourStart, hourEnd)
                var hourStart = new TimeSpan(displayHour, 0, 0);
                var hourEnd = new TimeSpan((displayHour + 1) % 24, 0, 0);
                
                // Count reservations that overlap with this hour across all reservations
                // This shows which hour has the most activity (reservations happening during that hour)
                var count = reservations.Count(r =>
                {
                    // Calculate reservation start and end times
                    var reservationStart = r.ReservationTime;
                    var reservationEnd = r.ReservationTime.Add(r.Duration);
                    
                    // Handle case where reservation end crosses midnight
                    if (reservationEnd < reservationStart)
                    {
                        reservationEnd = reservationEnd.Add(TimeSpan.FromDays(1));
                    }
                    
                    // Handle case where hour end crosses midnight
                    TimeSpan actualHourEnd = hourEnd;
                    if (hourEnd < hourStart)
                    {
                        actualHourEnd = hourEnd.Add(TimeSpan.FromDays(1));
                    }
                    
                    // Check overlap using half-open interval logic: start1 < end2 AND start2 < end1
                    // This means the reservation is active during this hour
                    bool overlaps = reservationStart < actualHourEnd && hourStart < reservationEnd;
                    
                    return overlaps;
                });

                hourlyData.Add(new
                {
                    hour = $"{displayHour:00}:00",
                    count = count,
                    color = "#6B8E7F" // Color will be determined on frontend based on table count
                });
            }

            return Ok(hourlyData);
        }

        [HttpGet("top-tables")]
        public async Task<ActionResult<List<object>>> GetTopTables([FromQuery] int? restaurantId = null, [FromQuery] int topCount = 3, [FromQuery] bool leastUsed = false)
        {
            if (!restaurantId.HasValue)
            {
                return BadRequest("restaurantId is required");
            }

            // Get tables with reservation counts
            var tablesWithCounts = await _context.Tables
                .Where(t => t.RestaurantId == restaurantId.Value && t.IsActive)
                .Select(t => new
                {
                    TableId = t.Id,
                    TableNumber = t.TableNumber,
                    Capacity = t.Capacity,
                    ReservationCount = t.Reservations.Count(r => r.Status != "Cancelled")
                })
                .ToListAsync();

            // Order by reservation count (ascending for least used, descending for most used)
            var orderedTables = leastUsed
                ? tablesWithCounts.OrderBy(t => t.ReservationCount).Take(topCount)
                : tablesWithCounts.OrderByDescending(t => t.ReservationCount).Take(topCount);

            var result = orderedTables.Select(t => new
            {
                tableId = t.TableId,
                tableNumber = t.TableNumber,
                capacity = t.Capacity,
                reservationCount = t.ReservationCount
            }).ToList();

            return Ok(result);
        }

        [HttpGet("reservations-summary")]
        public async Task<ActionResult<object>> GetReservationsSummary([FromQuery] int? restaurantId = null)
        {
            if (!restaurantId.HasValue)
            {
                return BadRequest("restaurantId is required");
            }

            // Get all reservations for the restaurant (total count)
            var allReservations = await _context.Reservations
                .Where(r => r.RestaurantId == restaurantId.Value)
                .ToListAsync();

            var totalReservations = allReservations.Count;
            var confirmedReservations = allReservations.Count(r => r.Status == "Confirmed");
            var completedReservations = allReservations.Count(r => r.Status == "Completed");
            var cancelledReservations = allReservations.Count(r => r.Status == "Cancelled" || r.CancelledAt != null);

            // Calculate trend (compare last 30 days with previous 30 days)
            var today = DateTime.Now.Date;
            var last30Days = today.AddDays(-30);
            var previous30DaysStart = last30Days.AddDays(-30);

            var recentReservations = await _context.Reservations
                .Where(r => r.RestaurantId == restaurantId.Value &&
                           r.ReservationDate >= last30Days &&
                           r.ReservationDate < today.AddDays(1))
                .CountAsync();

            var previousReservations = await _context.Reservations
                .Where(r => r.RestaurantId == restaurantId.Value &&
                           r.ReservationDate >= previous30DaysStart &&
                           r.ReservationDate < last30Days)
                .CountAsync();

            var trend = previousReservations > 0
                ? (double)(recentReservations - previousReservations) / previousReservations * 100
                : recentReservations > 0 ? 100 : 0;

            return Ok(new
            {
                total = totalReservations,
                confirmed = confirmedReservations,
                completed = completedReservations,
                cancelled = cancelledReservations,
                trend = Math.Round(trend, 1)
            });
        }

        [HttpGet("average-rating")]
        public async Task<ActionResult<object>> GetAverageRating([FromQuery] int? restaurantId = null)
        {
            if (!restaurantId.HasValue)
            {
                return BadRequest("restaurantId is required");
            }

            var reviews = await _context.Reviews
                .Where(r => r.RestaurantId == restaurantId.Value)
                .ToListAsync();

            if (!reviews.Any())
            {
                return Ok(new
                {
                    averageRating = 0.0,
                    totalReviews = 0,
                    trend = 0.0
                });
            }

            var averageRating = reviews.Average(r => (double)r.Rating);

            // Calculate trend (compare with previous 30 days)
            var today = DateTime.Now.Date;
            var last30Days = today.AddDays(-30);
            var recentReviews = reviews.Where(r => r.CreatedAt >= last30Days).ToList();
            var previousReviews = reviews.Where(r => r.CreatedAt < last30Days).ToList();

            var recentAverage = recentReviews.Any() ? recentReviews.Average(r => (double)r.Rating) : averageRating;
            var previousAverage = previousReviews.Any() ? previousReviews.Average(r => (double)r.Rating) : averageRating;

            var trend = previousAverage > 0
                ? (recentAverage - previousAverage) / previousAverage * 100
                : recentAverage > 0 ? 100 : 0;

            return Ok(new
            {
                averageRating = Math.Round(averageRating, 1),
                totalReviews = reviews.Count,
                trend = Math.Round(trend, 1)
            });
        }

        [HttpGet("weekly-occupancy")]
        public async Task<ActionResult<List<object>>> GetWeeklyOccupancy([FromQuery] int? restaurantId = null)
        {
            if (!restaurantId.HasValue)
            {
                return BadRequest("restaurantId is required");
            }

            // Get all reservations for the restaurant (non-cancelled)
            var reservations = await _context.Reservations
                .Where(r => r.RestaurantId == restaurantId.Value &&
                           r.Status != "Cancelled" &&
                           r.CancelledAt == null)
                .ToListAsync();

            // Group by day of week and count reservations
            // DayOfWeek: Sunday=0, Monday=1, ..., Saturday=6
            var daysOfWeek = new[] { "Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun" };
            var weeklyData = new List<object>();

            for (int dayOfWeekIndex = 0; dayOfWeekIndex < 7; dayOfWeekIndex++)
            {
                // Convert array index to DayOfWeek enum
                // Array: Mon=0, Tue=1, ..., Sun=6
                // DayOfWeek: Sunday=0, Monday=1, ..., Saturday=6
                // So: Mon (array 0) -> Monday (DayOfWeek 1), ..., Sun (array 6) -> Sunday (DayOfWeek 0)
                DayOfWeek dayOfWeek;
                if (dayOfWeekIndex == 6) // Sunday
                    dayOfWeek = DayOfWeek.Sunday;
                else
                    dayOfWeek = (DayOfWeek)(dayOfWeekIndex + 1);

                var reservationCount = reservations.Count(r => r.ReservationDate.DayOfWeek == dayOfWeek);

                weeklyData.Add(new
                {
                    day = daysOfWeek[dayOfWeekIndex],
                    reservationCount = reservationCount
                });
            }

            return Ok(weeklyData);
        }
    }
}

