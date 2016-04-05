require 'test_helper'
require 'capybara/rails'

class UserFlowsTest < ActionDispatch::IntegrationTest
  self.use_transactional_fixtures = false 

  setup do 
    @david = User.create(first_name: "David", last_name: "Smith", email: "david@mail.com", password: Devise::Encryptor.digest(User, "helloworld"))
    @steve = User.create(first_name: "Steve", last_name: "Smith", email: "steve@mail.com", password: Devise::Encryptor.digest(User, "hellopassword"))
  end
  
  def login_david
    visit '/'
    fill_in "Email", with: @david.email
    fill_in "Password", with: @david.password
    click_button('Log in')
  end

  def login_steve
    visit '/'
    fill_in "Email", with: @steve.email
    fill_in "Password", with: @steve.password
    click_button('Log in')
  end

  def setup_steve_thought
    login_steve
    visit '/'
    fill_in "thought[content]", with: "This is Steve's thought!"
    click_button "post"
    click_link "Sign Out"
  end


  
  test "user logs in and browses site then signs out" do
   Capybara.use_default_driver  
   login_david
   click_link "Connect"
   assert page.has_content?("#{users(:amy).first_name}")
   click_link "Profile"
   assert page.has_content?("#{@david.first_name}'s Thoughts")
   click_link "Feed"
   assert page.has_css?('#feed_loop')
   click_link "Sign Out"
   assert_equal current_path, user_session_path
  end
  
  test "user logs in and creates a new thought from the feed page" do 
    Capybara.use_default_driver 
    login_david
    visit '/'
    fill_in "thought[content]", with: "Hello World! This is a thought"
    click_button "post"
    within '#feed_loop' do 
        assert page.has_content?("Hello World! This is a thought")
    end
  end
  
  
  test "user logs in and posts a thought from their profile page" do 
    Capybara.use_default_driver 
    login_david
    click_link "Profile"
    fill_in "thought[content]", with: "Hello Everyone!"
    click_button "post"
    within "#profile_thoughts_loop" do 
        assert page.has_content?("Hello Everyone!")
    end
  end
  
  test "user  posts then deletes a thought from the profile page" do
    Capybara.current_driver = :selenium
    login_david
    click_link "Profile"
    fill_in "thought[content]", with: "Hello Everyone!"
    click_button "post"
    within "#profile_thoughts_loop" do 
        assert page.has_content?("Hello Everyone!")
        click_link "Destroy"
        page.accept_alert
        assert_not page.has_content?("Hello Everyone!")
    end  
  end

  test "user logs in and makes a post from the feed page and deletes it" do 
    Capybara.current_driver = :selenium
    login_steve
    fill_in "thought[content]", with: "Hey Everyone"
    click_button "post"
    within "#feed_loop" do 
      assert page.has_content?("Hey Everyone")
      click_link "Destroy"
      page.accept_alert
      assert_not page.has_content?("Hey Everyone")
    end
  end

  test "user friendship is sent and accepted, can then see friends thoughts" do 
    Capybara.current_driver = :selenium
    setup_steve_thought
    login_david
    click_link "Connect"
    page.all(:link, "Add Friend")[8].click
    click_link "Sign Out"
    login_steve
    click_link "Connect"
    click_button "Accept"
    click_link "Sign Out"
    login_david
    assert page.has_content?("This is Steve's thought!")
  end
end