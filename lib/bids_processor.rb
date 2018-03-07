class BidsProcessor

	def self.params(resolution, params)
		case resolution
		when 1
			return params.require(:bid).permit(:bid_percentage, :project_id, :resolution_id, :vesting_period)
		when 2
			return params.require(:bid).permit(:project_id, :resolution_id)
		when 3
			return params.require(:bid).permit(:bid_percentage, :project_id, :resolution_id)
		end
	end

	def self.process(resolution, bid, params)
		project = Project.find(bid.project_id)
		bid_perc = bid.bid_percentage.to_f

		case resolution
		
		# Add collaborator
		when 1
			# Initiator already a member of project
			if project.has_employee?(new_user.id)
				return false, ""
			# Requested bid percentage more than available 
			elsif project.unallocated_percentage < bid_perc
	          	return false, "Bid could not be created as your demands cannot be met."
			# Added from dashboard
			elsif project.has_employee?(bid.initiator_id)
				# Email not specified
				unless params[:bid][:email].present?
					return false, ""
				else
					new_user = User.where(email: params[:bid][:email]).first
					# No user with email
					if new_user.nil?
						return false, ""
					end
	        		bid.user_id = new_user.id
	        		return true, bid
				end
        	# Bid by new user
      		else
      			new_user = User.find(params[:bid][:user_id])
      			# Does user exist?
      			if new_user.nil?
      				return false, ""
      			end
        		bid.user_id = new_user.id
        		return true, bid
      		end

		# Remove Collaborator
		when 2
			# Initiator not a member of project?
			unless project.has_employee?(bid.initiator_id)
				return false, ""
			# New user already member?
			elsif project.has_employee?(params[:bid][:user_id])
				return false, ""
			else
				remove_user = User.find(params[:bid][:user_id])
				if remove_user.nil?
					return false, ""
				end
				bid.user_id = remove_user.id
        		return true, bid
			end


		# Dilution
		when 3
			# Initiator not a member of project?
			unless project.has_employee?(bid.initiator_id)
				return false, ""
			else
				return true, bid
			end

		end
	end
end