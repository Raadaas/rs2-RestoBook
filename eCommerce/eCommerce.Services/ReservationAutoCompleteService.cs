using eCommerce.Model;
using eCommerce.Services.Database;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using System;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;

namespace eCommerce.Services
{
    /// <summary>
    /// Background service that automatically:
    /// 1. Completes confirmed reservations when their EndTime has passed.
    /// 2. Expires requested reservations when their EndTime has passed without being confirmed.
    /// </summary>
    public class ReservationAutoCompleteService : BackgroundService
    {
        private readonly IServiceProvider _serviceProvider;
        private readonly ILogger<ReservationAutoCompleteService> _logger;
        private readonly TimeSpan _checkInterval = TimeSpan.FromMinutes(1); // Check every minute

        public ReservationAutoCompleteService(
            IServiceProvider serviceProvider,
            ILogger<ReservationAutoCompleteService> logger)
        {
            _serviceProvider = serviceProvider;
            _logger = logger;
        }

        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            _logger.LogInformation("ReservationAutoCompleteService is starting.");

            while (!stoppingToken.IsCancellationRequested)
            {
                try
                {
                    await AutoCompleteReservationsAsync(stoppingToken);
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Error occurred while auto-completing reservations.");
                }

                await Task.Delay(_checkInterval, stoppingToken);
            }

            _logger.LogInformation("ReservationAutoCompleteService is stopping.");
        }

        private async Task AutoCompleteReservationsAsync(CancellationToken cancellationToken)
        {
            using var scope = _serviceProvider.CreateScope();
            var dbContext = scope.ServiceProvider.GetRequiredService<eCommerceDbContext>();

            var now = DateTime.UtcNow;

            // Find all confirmed reservations
            var confirmedReservations = await dbContext.Reservations
                .Where(r => r.State == ReservationState.Confirmed)
                .ToListAsync(cancellationToken);

            // Find all requested reservations
            var requestedReservations = await dbContext.Reservations
                .Where(r => r.State == ReservationState.Requested)
                .ToListAsync(cancellationToken);

            var completedCount = 0;
            var expiredCount = 0;

            // Process confirmed reservations - complete them if EndTime has passed
            foreach (var reservation in confirmedReservations)
            {
                // Calculate EndTime: ReservationDate.Date.Add(ReservationTime).Add(Duration)
                // EndTime is a computed property, so we need to calculate it manually
                var startTime = reservation.ReservationDate.Date.Add(reservation.ReservationTime);
                var endTime = startTime.Add(reservation.Duration);

                // Compare with UTC now
                // If ReservationDate is stored in local time, we need to handle timezone conversion
                // For now, assuming ReservationDate is in UTC or we compare as-is
                if (endTime <= now)
                {
                    try
                    {
                        reservation.Complete();
                        completedCount++;
                        _logger.LogInformation(
                            "Auto-completed reservation {ReservationId} (EndTime: {EndTime:yyyy-MM-dd HH:mm:ss})",
                            reservation.Id,
                            endTime);
                    }
                    catch (InvalidOperationException ex)
                    {
                        _logger.LogWarning(
                            ex,
                            "Cannot auto-complete reservation {ReservationId}: {Message}",
                            reservation.Id,
                            ex.Message);
                    }
                }
            }

            // Process requested reservations - expire them if EndTime has passed
            foreach (var reservation in requestedReservations)
            {
                // Calculate EndTime: ReservationDate.Date.Add(ReservationTime).Add(Duration)
                var startTime = reservation.ReservationDate.Date.Add(reservation.ReservationTime);
                var endTime = startTime.Add(reservation.Duration);

                // If EndTime has passed, expire the reservation
                if (endTime <= now)
                {
                    try
                    {
                        reservation.Expire();
                        expiredCount++;
                        _logger.LogInformation(
                            "Auto-expired reservation {ReservationId} (EndTime: {EndTime:yyyy-MM-dd HH:mm:ss})",
                            reservation.Id,
                            endTime);
                    }
                    catch (InvalidOperationException ex)
                    {
                        _logger.LogWarning(
                            ex,
                            "Cannot auto-expire reservation {ReservationId}: {Message}",
                            reservation.Id,
                            ex.Message);
                    }
                }
            }

            if (completedCount > 0 || expiredCount > 0)
            {
                await dbContext.SaveChangesAsync(cancellationToken);
                if (completedCount > 0)
                {
                    _logger.LogInformation(
                        "Auto-completed {Count} reservation(s).",
                        completedCount);
                }
                if (expiredCount > 0)
                {
                    _logger.LogInformation(
                        "Auto-expired {Count} reservation(s).",
                        expiredCount);
                }
            }
        }
    }
}
