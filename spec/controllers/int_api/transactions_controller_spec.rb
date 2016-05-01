require 'spec_helper'

describe TransactionsController, type: :controller do
  # Prerequisites
  before(:each) do
    @community = FactoryGirl.create(:community)
    @request.host = "#{@community.ident}.lvh.me"
    @company = FactoryGirl.create(:company, organization_name: "AAA")
    @employee = FactoryGirl.create(:employee, organization_name: "", is_organization: 0)
    @employee2 = FactoryGirl.create(:employee, organization_name: "", is_organization: 0)
    @company_untrusted = FactoryGirl.create(:company, organization_name: "BBB")
    @employee_other = FactoryGirl.create(:employee, organization_name: "", is_organization: 0)
    @company_trusted = FactoryGirl.create(:company, organization_name: "CCC")
    @employee_trusted = FactoryGirl.create(:employee, organization_name: "", is_organization: 0)

    FactoryGirl.create( :employment,
                        :company => @company,
                        :employee => @employee,
                        :active => true)
    FactoryGirl.create( :employment,
                        :company => @company,
                        :employee => @employee2,
                        :active => true)
    FactoryGirl.create( :employment,
                        :company => @company_untrusted,
                        :employee => @employee_other,
                        :active => true)
    FactoryGirl.create( :employment,
                        :company => @company_trusted,
                        :employee => @employee_trusted,
                        :active => true)
    @listing_all = FactoryGirl.create(:listing,
                                      :community_id => @community.id,
                                      :title => "Listing_all",
                                      :author => @company,
                                      :availability => "all")
    @listing_trusted = FactoryGirl.create(:listing,
                                      :community_id => @community.id,
                                      :title => "Listing_trusted",
                                      :author => @company,
                                      :availability => "trusted")
    @listing_intern = FactoryGirl.create(:listing,
                                      :community_id => @community.id,
                                      :title => "Listing_intern",
                                      :author => @company,
                                      :availability => "intern")

    @community.members << @company
    @community.members << @company_untrusted
    @community.members << @company_trusted
    @community.members << @employee
    @community.members << @employee2
    @community.members << @employee_other
    @community.members << @employee_trusted

    @company.followed_people << @company_trusted

    expect(Person.find_by_id(@company.id)).not_to be_nil
    expect(Person.find_by_id(@employee.id)).not_to be_nil
    expect(Person.find_by_id(@employee2.id)).not_to be_nil
    expect(Person.find_by_id(@company_untrusted.id)).not_to be_nil
    expect(Person.find_by_id(@employee_other.id)).not_to be_nil
    expect(Person.find_by_id(@company_trusted.id)).not_to be_nil
    expect(Person.find_by_id(@employee_trusted.id)).not_to be_nil
  end


  describe "#create" do
    def pooltool_manipulation(person_username, employee_username, listing_id)
      last_trans = Transaction.last
      post :create, { person_id: person_username,
                      poolTool: true,
                      message: "Booked with Pool Tool",
                      employee: {username: employee_username},
                      listing_id: listing_id,
                      start_on: "2025-01-01",
                      end_on: "2025-01-05",
                      commit: "Create",
                      description: "abc"
                    }

      # Redirect & no new transaction
      expect(response.status).to eq(302)
      expect(Transaction.last).to eq(last_trans)
    end

    def pooltool_successful_create_transaction(person_username, employee, listing_id, display_name, type)
      last_trans_before = Transaction.last
      last_booking_before = Booking.last

      post :create, { person_id: person_username,
                      poolTool: true,
                      message: "Booked with Pool Tool",
                      employee: {username: employee.username},
                      listing_id: listing_id,
                      start_on: "2025-01-01",
                      end_on: "2025-01-05",
                      commit: "Create",
                      description: "abc"
                    }

      # Check database entries
      last_trans = Transaction.last
      last_booking = Booking.last
      expect(last_trans).not_to eq(last_trans_before)
      expect(last_booking).not_to eq(last_booking_before)

      # Check response status code
      expect(response.status).to eq(200)

      # Check response
      resp = eval(response.body.gsub(/:/, '=>'))  # Response string to hash
      expect(resp).to eq({
        "status" => "success",
        "type" => type,
        "empl_or_reason" => display_name,
        "start_on" => "2025-01-01",
        "end_on" => "2025-01-05",
        "listing_id" => listing_id.to_s,
        "transaction_id" => last_trans.id,
        "renter_id" => employee.id,
        "description" => "abc"
        })
    end

    describe "Pool Tool" do
      it "PoolTool: Company admin can book public listing for company employee" do
        display_name = @employee.family_name + " " + @employee.given_name

        sign_in_for_spec(@company)
        pooltool_successful_create_transaction(@company.username,
                                               @employee,
                                               @listing_all.id,
                                               display_name,
                                               "ownEmployee")
      end
      it "PoolTool: Company admin can book trusted listing for company employee" do
        display_name = @employee.family_name + " " + @employee.given_name

        sign_in_for_spec(@company)
        pooltool_successful_create_transaction(@company.username,
                                               @employee,
                                               @listing_trusted.id,
                                               display_name,
                                               "ownEmployee")
      end
      it "PoolTool: Company admin can book trusted intern for company employee" do
        display_name = @employee.family_name + " " + @employee.given_name

        sign_in_for_spec(@company)
        pooltool_successful_create_transaction(@company.username,
                                               @employee,
                                               @listing_intern.id,
                                               display_name,
                                               "ownEmployee")
      end


      it "PoolTool: Company employee can book public listing" do
        display_name = @employee.family_name + " " + @employee.given_name
        sign_in_for_spec(@employee)
        pooltool_successful_create_transaction(@employee.username,
                                               @employee,
                                               @listing_all.id,
                                               display_name,
                                               "ownEmployee")
      end
      it "PoolTool: Company employee can book trusted listing" do
        display_name = @employee.family_name + " " + @employee.given_name
        sign_in_for_spec(@employee)
        pooltool_successful_create_transaction(@employee.username,
                                               @employee,
                                               @listing_trusted.id,
                                               display_name,
                                               "ownEmployee")
      end
      it "PoolTool: Company employee can book intern listing" do
        display_name = @employee.family_name + " " + @employee.given_name
        sign_in_for_spec(@employee)
        pooltool_successful_create_transaction(@employee.username,
                                               @employee,
                                               @listing_intern.id,
                                               display_name,
                                               "ownEmployee")
      end


      it "PoolTool: Company admin can book public listing with another reason" do
        # Temporary store last db entries for comparison
        last_trans_before = Transaction.last
        last_booking_before = Booking.last

        sign_in_for_spec(@company)
        post :create, { person_id: @company.username,
                        poolTool: true,
                        message: "Booked with Pool Tool",
                        renter: "Maintainance",
                        listing_id: @listing_all.id,
                        start_on: "2025-01-01",
                        end_on: "2025-01-05",
                        commit: "Create",
                        description: "abc"
                      }

        # Check database entries
        last_trans = Transaction.last
        last_booking = Booking.last
        expect(last_trans).not_to eq(last_trans_before)
        expect(last_booking).not_to eq(last_booking_before)

        # Check response status code
        expect(response.status).to eq(200)

        # Check response
        resp = eval(response.body.gsub(/:/, '=>'))  # Response string to hash
        expect(resp).to eq({
          "status" => "success",
          "type" => "otherReason",
          "empl_or_reason" => "Maintainance",
          "start_on" => "2025-01-01",
          "end_on" => "2025-01-05",
          "listing_id" => @listing_all.id.to_s,
          "transaction_id" => last_trans.id,
          "renter_id" => @company.id,
          "description" => "abc"
          })
      end
      it "PoolTool: Company admin can book trusted listing with another reason" do
        # Temporary store last db entries for comparison
        last_trans_before = Transaction.last
        last_booking_before = Booking.last

        sign_in_for_spec(@company)
        post :create, { person_id: @company.username,
                        poolTool: true,
                        message: "Booked with Pool Tool",
                        renter: "Maintainance",
                        listing_id: @listing_trusted.id,
                        start_on: "2025-01-01",
                        end_on: "2025-01-05",
                        commit: "Create",
                        description: "abc"
                      }

        # Check database entries
        last_trans = Transaction.last
        last_booking = Booking.last
        expect(last_trans).not_to eq(last_trans_before)
        expect(last_booking).not_to eq(last_booking_before)

        # Check response status code
        expect(response.status).to eq(200)

        # Check response
        resp = eval(response.body.gsub(/:/, '=>'))  # Response string to hash
        expect(resp).to eq({
          "status" => "success",
          "type" => "otherReason",
          "empl_or_reason" => "Maintainance",
          "start_on" => "2025-01-01",
          "end_on" => "2025-01-05",
          "listing_id" => @listing_trusted.id.to_s,
          "transaction_id" => last_trans.id,
          "renter_id" => @company.id,
          "description" => "abc"
          })
      end
      it "PoolTool: Company admin can book intern listing with another reason" do
        # Temporary store last db entries for comparison
        last_trans_before = Transaction.last
        last_booking_before = Booking.last

        sign_in_for_spec(@company)
        post :create, { person_id: @company.username,
                        poolTool: true,
                        message: "Booked with Pool Tool",
                        renter: "Maintainance",
                        listing_id: @listing_intern.id,
                        start_on: "2025-01-01",
                        end_on: "2025-01-05",
                        commit: "Create",
                        description: "abc"
                      }

        # Check database entries
        last_trans = Transaction.last
        last_booking = Booking.last
        expect(last_trans).not_to eq(last_trans_before)
        expect(last_booking).not_to eq(last_booking_before)

        # Check response status code
        expect(response.status).to eq(200)

        # Check response
        resp = eval(response.body.gsub(/:/, '=>'))  # Response string to hash
        expect(resp).to eq({
          "status" => "success",
          "type" => "otherReason",
          "empl_or_reason" => "Maintainance",
          "start_on" => "2025-01-01",
          "end_on" => "2025-01-05",
          "listing_id" => @listing_intern.id.to_s,
          "transaction_id" => last_trans.id,
          "renter_id" => @company.id,
          "description" => "abc"
          })
      end


      it "PoolTool: Trusted company admin can book public listing" do
        sign_in_for_spec(@company_trusted)

        last_trans_before = Transaction.last
        last_booking_before = Booking.last

        post :create, { person_id: @company_trusted.username,
                        poolTool: true,
                        message: "Booked with Pool Tool",
                        employee: "",
                        listing_id: @listing_all.id,
                        start_on: "2025-01-01",
                        end_on: "2025-01-05",
                        commit: "Create",
                        description: "abc"
                      }

        # Check database entries
        last_trans = Transaction.last
        last_booking = Booking.last
        expect(last_trans).not_to eq(last_trans_before)
        expect(last_booking).not_to eq(last_booking_before)

        # Check response status code
        expect(response.status).to eq(200)

        # Check response
        resp = eval(response.body.gsub(/:/, '=>'))  # Response string to hash
        display_name = @company_trusted.organization_name
        expect(resp).to eq({
          "status" => "success",
          "type" => "trustedCompany",
          "empl_or_reason" => display_name,
          "start_on" => "2025-01-01",
          "end_on" => "2025-01-05",
          "listing_id" => @listing_all.id.to_s,
          "transaction_id" => last_trans.id,
          "renter_id" => @company_trusted.id,
          "description" => "abc"
          })
      end
      it "PoolTool: Trusted company admin can book trusted listing" do
        sign_in_for_spec(@company_trusted)

        last_trans_before = Transaction.last
        last_booking_before = Booking.last

        post :create, { person_id: @company_trusted.username,
                        poolTool: true,
                        message: "Booked with Pool Tool",
                        employee: "",
                        listing_id: @listing_trusted.id,
                        start_on: "2025-01-01",
                        end_on: "2025-01-05",
                        commit: "Create",
                        description: "abc"
                      }

        # Check database entries
        last_trans = Transaction.last
        last_booking = Booking.last
        expect(last_trans).not_to eq(last_trans_before)
        expect(last_booking).not_to eq(last_booking_before)

        # Check response status code
        expect(response.status).to eq(200)

        # Check response
        resp = eval(response.body.gsub(/:/, '=>'))  # Response string to hash
        display_name = @company_trusted.organization_name
        expect(resp).to eq({
          "status" => "success",
          "type" => "trustedCompany",
          "empl_or_reason" => display_name,
          "start_on" => "2025-01-01",
          "end_on" => "2025-01-05",
          "listing_id" => @listing_trusted.id.to_s,
          "transaction_id" => last_trans.id,
          "renter_id" => @company_trusted.id,
          "description" => "abc"
          })
      end


      it "PoolTool: No new booking because invalid dates" do
        sign_in_for_spec(@company)
        last_trans = Transaction.last
        post :create, { person_id: @company.username,
                        poolTool: true,
                        message: "Booked with Pool Tool",
                        employee: {username: @employee.username},
                        listing_id: @listing_all.id,
                        start_on: "2025-05-01",
                        end_on: "2025-01-01",
                        commit: "Create",
                        description: "abc"
                      }

        # No redirect but also no new transaction
        expect(response.status).to eq(200)
        resp = eval(response.body.gsub(/:/, '=>'))  # Response string to hash
        expect(resp).to include({ "status" => "error"})
        expect(Transaction.last).to eq(last_trans)
      end

      it "PoolTool Manipulation: Company employee can not book for any employee" do
        sign_in_for_spec(@employee)
        pooltool_manipulation(@employee2.username, @employee2.username, @listing_all.id)
      end

      it "PoolTool Manipulation: Trusted company can not book for pool tool owners employee" do
        sign_in_for_spec(@company_trusted)

        last_trans_before = Transaction.last
        last_booking_before = Booking.last

        post :create, { person_id: @employee.username,
                        poolTool: true,
                        message: "Booked with Pool Tool",
                        employee: {username: @employee.username},
                        listing_id: @listing_all.id,
                        start_on: "2025-01-01",
                        end_on: "2025-01-05",
                        commit: "Create",
                        description: "abc"
                      }

        # Check database entries
        last_trans = Transaction.last
        last_booking = Booking.last
        expect(last_trans).not_to eq(last_trans_before)
        expect(last_booking).not_to eq(last_booking_before)

        # Check response status code
        expect(response.status).to eq(200)

        # Check response
        resp = eval(response.body.gsub(/:/, '=>'))  # Response string to hash
        expect(resp).to eq({
          "status" => "success",
          "type" => "trustedCompany",
          "empl_or_reason" => @company_trusted.organization_name,
          "start_on" => "2025-01-01",
          "end_on" => "2025-01-05",
          "listing_id" => @listing_all.id.to_s,
          "transaction_id" => last_trans.id,
          "renter_id" => @company_trusted.id,
          "description" => "abc"
          })
      end


      # EXTERN LISTINGS
      it "PoolTool Manipulation: Public listing can not be booked by logged out user" do
        pooltool_manipulation(@company.username, @employee.username, @listing_all.id)
      end

      it "PoolTool Manipulation: Public listing can not be booked by untrusted company" do
        sign_in_for_spec(@company_untrusted)
        pooltool_manipulation(@company.username, @employee.username, @listing_all.id)
      end

      it "PoolTool Manipulation: Public listing can not be booked by untrusted employee" do
        sign_in_for_spec(@employee_other)
        pooltool_manipulation(@company.username, @employee.username, @listing_all.id)
      end


      # TRUSTED LISTINGS
      it "PoolTool Manipulation: Trusted listing can not be booked by logged out user" do
        pooltool_manipulation(@company.username, @employee.username, @listing_trusted.id)
      end

      it "PoolTool Manipulation: Trusted listing can not be booked by untrusted company" do
        sign_in_for_spec(@company_untrusted)
        pooltool_manipulation(@company.username, @company_untrusted.username, @listing_trusted.id)
      end


      # INTERN LISTINGS
      it "PoolTool Manipulation: Intern listing can not be booked by logged out user" do
        pooltool_manipulation(@company.username, @employee.username, @listing_intern.id)
      end

      it "PoolTool Manipulation: Intern listing can not be booked by untrusted company" do
        sign_in_for_spec(@company_untrusted)
        pooltool_manipulation(@company.username, @employee.username, @listing_intern.id)
      end

    end
  end



  describe "#destroy" do
    describe "Pool Tool" do

      describe "Logged out" do
        it "No destroy as logged out user" do
          post :destroy, { person_id: 1, id: 1 }
          expect(response.status).to eq(302)
        end
      end


      describe "Logged in" do
        before(:each) do
          sign_in_for_spec(@company)
          post :create, { person_id: @company.username,
                          poolTool: true,
                          message: "Booked with Pool Tool",
                          employee: {username: @employee.username},
                          listing_id: @listing_all.id,
                          start_on: "2025-01-01",
                          end_on: "2025-01-05",
                          commit: "Create",
                          description: "abc"
                        }

          @transaction_id = Transaction.last.id
        end

        it "Delete any booking as signed in company admin" do
          tr_count = Transaction.all.count
          post :destroy, { person_id: @company.username, id: @transaction_id }
          expect(response.status).to eq(200)
          expect(Transaction.all.count).to eq(tr_count)
          expect(Transaction.find(@transaction_id).current_state).to eq("canceled")
          resp = eval(response.body.gsub(/:/, '=>'))  # Response string to hash
          expect(resp).to include({ "status" => "success"})
        end

        it "Delete own booking as signed in employee" do
          sign_in_for_spec(@employee)
          tr_count = Transaction.all.count
          post :destroy, { person_id: @company.username, id: @transaction_id }
          expect(response.status).to eq(200)
          expect(Transaction.all.count).to eq(tr_count)
          expect(Transaction.find(@transaction_id).current_state).to eq("canceled")
          resp = eval(response.body.gsub(/:/, '=>'))  # Response string to hash
          expect(resp).to include({ "status" => "success"})
        end

        it "No destroy if same company but other employee" do
          sign_in_for_spec(@employee2)
          tr_count = Transaction.all.count
          post :destroy, { person_id: @company.username, id: @transaction_id }
          expect(response.status).to eq(302)
          expect(Transaction.all.count).to eq(tr_count)
        end

        it "No destroy if other company admin" do
          sign_in_for_spec(@company_untrusted)
          tr_count = Transaction.all.count
          post :destroy, { person_id: @company.username, id: @transaction_id }
          expect(response.status).to eq(302)
          expect(Transaction.all.count).to eq(tr_count)
        end

        it "No destroy if other company employee" do
          sign_in_for_spec(@employee_other)
          tr_count = Transaction.all.count
          post :destroy, { person_id: @company.username, id: @transaction_id }
          expect(response.status).to eq(302)
          expect(Transaction.all.count).to eq(tr_count)
        end

      end
    end
  end


  describe "#update" do
    describe "Pool Tool" do

      describe "Logged out" do
        it "No update as logged out user" do
          post :update, { person_id: 1, id: 1 }
          expect(response.status).to eq(302)
        end
      end


      # describe "logged in" do
      #   before(:each) do
      #     sign_in_for_spec(@company)
      #     post :create, { person_id: @company.username,
      #                     poolTool: true,
      #                     message: "Booked with Pool Tool",
      #                     employee: {username: @employee.username},
      #                     listing_id: @listing_all.id,
      #                     start_on: "2025-01-01",
      #                     end_on: "2025-01-05",
      #                     commit: "Create",
      #                     description: "abc"
      #                   }

      #     @transaction_id = Transaction.last.id
      #   end

      #   it "Update any booking as signed in company admin" do
      #     tr_count = Transaction.all.count
      #     post :update, { person_id: @company.username,
      #                     id: @transaction_id,
      #                     from: "Wed Sep 30 2025 02:00:00 GMT+0200 (CEST)",
      #                     to: "Wed Sep 30 2025 02:00:00 GMT+0200 (CEST)"
      #                   }
      #     expect(response.status).to eq(200)
      #     resp = eval(response.body.gsub(/:/, '=>'))  # Response string to hash
      #     expect(resp).to include({ "status" => "success"})
      #   end

      #   it "Update own booking as signed in employee" do
      #     sign_in_for_spec(@employee)
      #     tr_count = Transaction.all.count
      #     post :update, { person_id: @company.username,
      #                     id: @transaction_id,
      #                     from: "Wed Sep 30 2025 02:00:00 GMT+0200 (CEST)",
      #                     to: "Wed Sep 30 2025 02:00:00 GMT+0200 (CEST)"
      #                    }
      #     expect(response.status).to eq(200)
      #     resp = eval(response.body.gsub(/:/, '=>'))  # Response string to hash
      #     expect(resp).to include({ "status" => "success"})
      #   end

      #   it "No update if invalid dates" do
      #     sign_in_for_spec(@company)
      #     tr_count = Transaction.all.count
      #     post :update, { person_id: @company.username,
      #                     id: @transaction_id,
      #                     from: "Wed Sep 30 2025 02:00:00 GMT+0200 (CEST)",
      #                     to: "Tue Sep 29 2025 02:00:00 GMT+0200 (CEST)"
      #                    }
      #     expect(response.status).to eq(200)
      #     resp = eval(response.body.gsub(/:/, '=>'))  # Response string to hash
      #     expect(resp).to include({ "status" => "error"})
      #   end

      #   it "No update if same company but other employee" do
      #     sign_in_for_spec(@employee2)
      #     tr_count = Transaction.all.count
      #     post :update, { person_id: @company.username,
      #                     id: @transaction_id,
      #                     from: "Wed Sep 30 2025 02:00:00 GMT+0200 (CEST)",
      #                     to: "Wed Sep 30 2025 02:00:00 GMT+0200 (CEST)"
      #                    }
      #     expect(response.status).to eq(302)
      #   end

      #   it "No update if other company admin" do
      #     sign_in_for_spec(@company_untrusted)
      #     tr_count = Transaction.all.count
      #     post :update,  {  person_id: @company.username,
      #                       id: @transaction_id,
      #                       from: "Wed Sep 30 2025 02:00:00 GMT+0200 (CEST)",
      #                       to: "Wed Sep 30 2025 02:00:00 GMT+0200 (CEST)"
      #                     }
      #     expect(response.status).to eq(302)
      #   end

      #   it "No update if other company employee" do
      #     sign_in_for_spec(@employee_other)
      #     tr_count = Transaction.all.count
      #     post :update, { person_id: @company.username,
      #                     id: @transaction_id,
      #                     from: "Wed Sep 30 2025 02:00:00 GMT+0200 (CEST)",
      #                     to: "Wed Sep 30 2025 02:00:00 GMT+0200 (CEST)"
      #                     }
      #     expect(response.status).to eq(302)
      #   end
      # end
    end
  end

end
