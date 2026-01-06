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

            var today = DateTime.Now.Date; // Use local time
            var tomorrow = today.AddDays(1);

            var query = _context.Reservations
                .Where(r => r.ReservationDate >= today && r.ReservationDate < tomorrow);

            query = query.Where(r => r.RestaurantId == restaurantId.Value);

            var reservations = await query.ToListAsync();

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
                
                // Count reservations that overlap with this hour
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
    }
}

