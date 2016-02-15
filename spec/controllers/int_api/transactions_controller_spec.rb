require 'spec_helper'

describe TransactionsController do
  # Prerequisites
  before(:each) do
    @community = FactoryGirl.create(:community)
    @request.host = "#{@community.ident}.lvh.me"
    @company = FactoryGirl.create(:company, organization_name: "AAA")
    @employee = FactoryGirl.create(:employee, organization_name: "", is_organization: 0)
    @employee2 = FactoryGirl.create(:employee, organization_name: "", is_organization: 0)
    @company_other = FactoryGirl.create(:company, organization_name: "BBB")
    @employee_other = FactoryGirl.create(:employee, organization_name: "", is_organization: 0)

    FactoryGirl.create( :employment,
                        :company => @company,
                        :employee => @employee,
                        :active => true)
    FactoryGirl.create( :employment,
                        :company => @company,
                        :employee => @employee2,
                        :active => true)
    FactoryGirl.create( :employment,
                        :company => @company_other,
                        :employee => @employee_other,
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
    @community.members << @company
    @community.members << @company_other
    @community.members << @employee
    @community.members << @employee2
    @community.members << @employee_other

    Person.find_by_id(@company.id).should_not be_nil
    Person.find_by_id(@employee.id).should_not be_nil
    Person.find_by_id(@employee2.id).should_not be_nil
    Person.find_by_id(@company_other.id).should_not be_nil
    Person.find_by_id(@employee_other.id).should_not be_nil
  end


  describe "#create" do
    describe "Pool Tool" do
      it "PoolTool: New booking for employee" do
        # Temporary store last db entries for comparison
        last_trans_before = Transaction.last
        last_booking_before = Booking.last

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

        # Check database entries
        last_trans = Transaction.last
        last_booking = Booking.last
        last_trans.should_not == last_trans_before
        last_booking.should_not == last_booking_before

        # Check response status code
        response.status.should == 200

        # Check response
        resp = eval(response.body.gsub(/:/, '=>'))  # Response string to hash
        display_name = @employee.family_name + " " + @employee.given_name
        resp.should == {
          "status" => "success",
          "employee" => true,
          "empl_or_reason" => display_name,
          "start_on" => "2025-01-01",
          "end_on" => "2025-01-05",
          "listing_id" => @listing_all.id.to_s,
          "transaction_id" => last_trans.id,
          "renter_id" => @employee.id,
          "description" => "abc"
          }
      end


      it "PoolTool: New booking as employee" do
        # Temporary store last db entries for comparison
        last_trans_before = Transaction.last
        last_booking_before = Booking.last

        sign_in_for_spec(@employee)
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

        # Check database entries
        last_trans = Transaction.last
        last_booking = Booking.last
        last_trans.should_not == last_trans_before
        last_booking.should_not == last_booking_before

        # Check response status code
        response.status.should == 200

        # Check response
        resp = eval(response.body.gsub(/:/, '=>'))  # Response string to hash
        display_name = @employee.family_name + " " + @employee.given_name
        resp.should == {
          "status" => "success",
          "employee" => true,
          "empl_or_reason" => display_name,
          "start_on" => "2025-01-01",
          "end_on" => "2025-01-05",
          "listing_id" => @listing_all.id.to_s,
          "transaction_id" => last_trans.id,
          "renter_id" => @employee.id,
          "description" => "abc"
          }
      end


      it "PoolTool: New booking because of another reason" do
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
        last_trans.should_not == last_trans_before
        last_booking.should_not == last_booking_before

        # Check response status code
        response.status.should == 200

        # Check response
        resp = eval(response.body.gsub(/:/, '=>'))  # Response string to hash
        resp.should == {
          "status" => "success",
          "employee" => false,
          "empl_or_reason" => "Maintainance",
          "start_on" => "2025-01-01",
          "end_on" => "2025-01-05",
          "listing_id" => @listing_all.id.to_s,
          "transaction_id" => last_trans.id,
          "renter_id" => @company.id,
          "description" => "abc"
          }
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
        response.status.should == 200
        resp = eval(response.body.gsub(/:/, '=>'))  # Response string to hash
        resp.should include({ "status" => "error"})
        Transaction.last.should == last_trans
      end


      it "PoolTool: No new booking if not logged in" do
        last_trans = Transaction.last
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

        # Redirect & no new transaction
        response.status.should == 302
        Transaction.last.should == last_trans
      end


      it "PoolTool: No new booking from another company" do
        last_trans = Transaction.last
        sign_in_for_spec(@company_other)
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
        # Redirect & no new transaction
        response.status.should == 302
        Transaction.last.should == last_trans
      end

      it "PoolTool: No new booking if employee is from another company" do
        last_trans = Transaction.last
        sign_in_for_spec(@employee_other)
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
        # Redirect & no new transaction
        response.status.should == 302
        Transaction.last.should == last_trans
      end

      it "PoolTool: No new booking if employee tries to book for other employee" do
        last_trans = Transaction.last
        sign_in_for_spec(@employee)
        post :create, { person_id: @company.username,
                        poolTool: true,
                        message: "Booked with Pool Tool",
                        employee: {username: @employee2.username},
                        listing_id: @listing_all.id,
                        start_on: "2025-01-01",
                        end_on: "2025-01-05",
                        commit: "Create",
                        description: "abc"
                      }
        # Redirect & no new transaction
        response.status.should == 302
        Transaction.last.should == last_trans
      end
    end
  end



  describe "#destroy" do
    describe "Pool Tool" do

      describe "Logged out" do
        it "No destroy as logged out user" do
          post :destroy, { id: 1 }
          response.status.should == 302
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
          response.status.should == 200
          Transaction.all.count.should == tr_count - 1
          resp = eval(response.body.gsub(/:/, '=>'))  # Response string to hash
          resp.should include({ "status" => "success"})
        end

        it "Delete own booking as signed in employee" do
          sign_in_for_spec(@employee)
          tr_count = Transaction.all.count
          post :destroy, { person_id: @company.username, id: @transaction_id }
          response.status.should == 200
          Transaction.all.count.should == tr_count - 1
          resp = eval(response.body.gsub(/:/, '=>'))  # Response string to hash
          resp.should include({ "status" => "success"})
        end

        it "No destroy if same company but other employee" do
          sign_in_for_spec(@employee2)
          tr_count = Transaction.all.count
          post :destroy, { person_id: @company.username, id: @transaction_id }
          response.status.should == 302
          Transaction.all.count.should == tr_count
        end

        it "No destroy if other company admin" do
          sign_in_for_spec(@company_other)
          tr_count = Transaction.all.count
          post :destroy, { person_id: @company.username, id: @transaction_id }
          response.status.should == 302
          Transaction.all.count.should == tr_count
        end

        it "No destroy if other company employee" do
          sign_in_for_spec(@employee_other)
          tr_count = Transaction.all.count
          post :destroy, { person_id: @company.username, id: @transaction_id }
          response.status.should == 302
          Transaction.all.count.should == tr_count
        end

      end
    end
  end


  describe "#update" do
    describe "Pool Tool" do

      describe "Logged out" do
        it "No update as logged out user" do
          post :update, { id: 1 }
          response.status.should == 302
        end
      end


      describe "logged in" do
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

        it "Update any booking as signed in company admin" do
          tr_count = Transaction.all.count
          post :update, { person_id: @company.username,
                          id: @transaction_id,
                          from: "Wed Sep 30 2025 02:00:00 GMT+0200 (CEST)",
                          to: "Wed Sep 30 2025 02:00:00 GMT+0200 (CEST)"
                        }
          response.status.should == 200
          resp = eval(response.body.gsub(/:/, '=>'))  # Response string to hash
          resp.should include({ "status" => "success"})
        end

        it "Update own booking as signed in employee" do
          sign_in_for_spec(@employee)
          tr_count = Transaction.all.count
          post :update, { person_id: @company.username,
                          id: @transaction_id,
                          from: "Wed Sep 30 2025 02:00:00 GMT+0200 (CEST)",
                          to: "Wed Sep 30 2025 02:00:00 GMT+0200 (CEST)"
                         }
          response.status.should == 200
          resp = eval(response.body.gsub(/:/, '=>'))  # Response string to hash
          resp.should include({ "status" => "success"})
        end

        it "No update if invalid dates" do
          sign_in_for_spec(@company)
          tr_count = Transaction.all.count
          post :update, { person_id: @company.username,
                          id: @transaction_id,
                          from: "Wed Sep 30 2025 02:00:00 GMT+0200 (CEST)",
                          to: "Tue Sep 29 2025 02:00:00 GMT+0200 (CEST)"
                         }
          response.status.should == 200
          resp = eval(response.body.gsub(/:/, '=>'))  # Response string to hash
          resp.should include({ "status" => "error"})
        end

        it "No update if same company but other employee" do
          sign_in_for_spec(@employee2)
          tr_count = Transaction.all.count
          post :update, { person_id: @company.username,
                          id: @transaction_id,
                          from: "Wed Sep 30 2025 02:00:00 GMT+0200 (CEST)",
                          to: "Wed Sep 30 2025 02:00:00 GMT+0200 (CEST)"
                         }
          response.status.should == 302
        end

        it "No update if other company admin" do
          sign_in_for_spec(@company_other)
          tr_count = Transaction.all.count
          post :update,  {  person_id: @company.username,
                            id: @transaction_id,
                            from: "Wed Sep 30 2025 02:00:00 GMT+0200 (CEST)",
                            to: "Wed Sep 30 2025 02:00:00 GMT+0200 (CEST)"
                          }
          response.status.should == 302
        end

        it "No update if other company employee" do
          sign_in_for_spec(@employee_other)
          tr_count = Transaction.all.count
          post :update, { person_id: @company.username,
                          id: @transaction_id,
                          from: "Wed Sep 30 2025 02:00:00 GMT+0200 (CEST)",
                          to: "Wed Sep 30 2025 02:00:00 GMT+0200 (CEST)"
                          }
          response.status.should == 302
        end
      end
    end
  end

end
