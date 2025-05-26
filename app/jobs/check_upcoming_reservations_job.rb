# app/jobs/check_upcoming_reservations_job.rb
class CheckUpcomingReservationsJob < ApplicationJob
  queue_as :default

  def perform
    now = Time.current.beginning_of_minute
    reservations = Reservation.includes(:participants).where(starts_at: now)

    reservations.each do |reservation|
      reservation.participants.each do |participant|
        AddParticipantToFacialJob.perform_later(participant.id, reservation.id)
      end
    end
  end
end
