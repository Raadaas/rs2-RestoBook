using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using eCommerce.Model;

namespace eCommerce.Services.Database
{
    public class Reservation
    {
        [Key]
        public int Id { get; set; }
        
        public int UserId { get; set; }
        
        [ForeignKey("UserId")]
        public User User { get; set; } = null!;
        
        public int RestaurantId { get; set; }
        
        [ForeignKey("RestaurantId")]
        public Restaurant Restaurant { get; set; } = null!;
        
        public int? TableId { get; set; }
        
        [ForeignKey("TableId")]
        public Table? Table { get; set; }
        
        public DateTime ReservationDate { get; set; }
        
        public TimeSpan ReservationTime { get; set; }
        
        public TimeSpan Duration { get; set; } = TimeSpan.FromHours(2); // Default 2 hours
        
        public int NumberOfGuests { get; set; }
        
        /// <summary>
        /// Gets the current state of the reservation.
        /// State can only be changed through the state machine methods (Edit, Confirm, Cancel, Complete).
        /// </summary>
        [Required]
        [Column(TypeName = "int")]
        public ReservationState State { get; private set; } = ReservationState.Requested;
        
        [MaxLength(500)]
        public string? SpecialRequests { get; set; }
        
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        
        public DateTime? ConfirmedAt { get; set; }
        
        public DateTime? CancelledAt { get; set; }
        
        [MaxLength(500)]
        public string? CancellationReason { get; set; }
        
        // Navigation properties
        public ICollection<ReservationHistory> History { get; set; } = new List<ReservationHistory>();
        public Review? Review { get; set; }

        /// <summary>
        /// Computed property that returns the start time of the reservation
        /// (combines ReservationDate and ReservationTime).
        /// </summary>
        [NotMapped]
        public DateTime StartTime => ReservationDate.Date.Add(ReservationTime);

        /// <summary>
        /// Computed property that returns the end time of the reservation
        /// (StartTime + Duration).
        /// </summary>
        [NotMapped]
        public DateTime EndTime => StartTime.Add(Duration);

        /// <summary>
        /// Allows editing reservation details. Only allowed when State is Requested.
        /// This method allows modification of reservation properties such as ReservationDate,
        /// ReservationTime, Duration, NumberOfGuests, and SpecialRequests.
        /// </summary>
        /// <param name="reservationDate">New reservation date.</param>
        /// <param name="reservationTime">New reservation time.</param>
        /// <param name="duration">New duration.</param>
        /// <param name="numberOfGuests">New number of guests.</param>
        /// <param name="specialRequests">New special requests (optional).</param>
        /// <exception cref="InvalidOperationException">Thrown when State is not Requested.</exception>
        public void Edit(DateTime reservationDate, TimeSpan reservationTime, TimeSpan duration, int numberOfGuests, string? specialRequests = null)
        {
            if (State != ReservationState.Requested)
            {
                throw new InvalidOperationException($"Cannot edit reservation. Editing is only allowed when State is {ReservationState.Requested}, but current State is {State}.");
            }

            ReservationDate = reservationDate;
            ReservationTime = reservationTime;
            Duration = duration;
            NumberOfGuests = numberOfGuests;
            SpecialRequests = specialRequests;
        }

        /// <summary>
        /// Confirms the reservation. Only allowed when State is Requested.
        /// Sets the ConfirmedAt timestamp to the current UTC time.
        /// </summary>
        /// <exception cref="InvalidOperationException">Thrown when State is not Requested.</exception>
        public void Confirm()
        {
            if (State != ReservationState.Requested)
            {
                throw new InvalidOperationException($"Cannot confirm reservation. Confirmation is only allowed when State is {ReservationState.Requested}, but current State is {State}.");
            }

            State = ReservationState.Confirmed;
            ConfirmedAt = DateTime.UtcNow;
        }

        /// <summary>
        /// Cancels the reservation. Allowed when State is Requested or Confirmed.
        /// Sets the CancelledAt timestamp to the current UTC time and optionally records a cancellation reason.
        /// </summary>
        /// <param name="reason">Optional cancellation reason.</param>
        /// <exception cref="InvalidOperationException">Thrown when State is not Requested or Confirmed.</exception>
        public void Cancel(string? reason = null)
        {
            if (State != ReservationState.Requested && State != ReservationState.Confirmed)
            {
                throw new InvalidOperationException($"Cannot cancel reservation. Cancellation is only allowed when State is {ReservationState.Requested} or {ReservationState.Confirmed}, but current State is {State}.");
            }

            State = ReservationState.Cancelled;
            CancelledAt = DateTime.UtcNow;
            CancellationReason = reason;
        }

        /// <summary>
        /// Marks the reservation as completed. Only allowed when State is Confirmed.
        /// This indicates that the dining experience has finished.
        /// </summary>
        /// <exception cref="InvalidOperationException">Thrown when State is not Confirmed.</exception>
        public void Complete()
        {
            if (State != ReservationState.Confirmed)
            {
                throw new InvalidOperationException($"Cannot complete reservation. Completion is only allowed when State is {ReservationState.Confirmed}, but current State is {State}.");
            }

            State = ReservationState.Completed;
        }

        /// <summary>
        /// Marks the reservation as expired. Only allowed when State is Requested.
        /// This is automatically called when a Requested reservation's EndTime has passed
        /// without being confirmed.
        /// </summary>
        /// <exception cref="InvalidOperationException">Thrown when State is not Requested.</exception>
        public void Expire()
        {
            if (State != ReservationState.Requested)
            {
                throw new InvalidOperationException($"Cannot expire reservation. Expiration is only allowed when State is {ReservationState.Requested}, but current State is {State}.");
            }

            State = ReservationState.Expired;
        }
    }
}
