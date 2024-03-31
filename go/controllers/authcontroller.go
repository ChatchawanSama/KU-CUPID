package controllers

import (
	"bytes"
	"crypto/rand"
	"crypto/rsa"
	"crypto/sha1"
	"crypto/x509"
	"encoding/base64"
	"encoding/json"
	"encoding/pem"
	"fmt"
	"ku_cupid/database"
	"ku_cupid/models"
	"math/big"
	"net/http"
	"strconv"

	"github.com/dgrijalva/jwt-go"
	"github.com/gofiber/fiber/v2"

	// "github.com/dgrijalva/jwt-go/v4"
	// "github.com/dgrijalva/jwt-go"
	"time"
)

var MYKU_RSA_PUBLIC_KEY = `-----BEGIN PUBLIC KEY-----
MIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEAytOhlq/JPcTN0fX+VqOb
E5kwIaDnEtso2KGHdi9y7uTtQA6pO4fsPNJqtXOdrcfDgp/EQifPwVRZpjdbVrD6
FgayrQQILAnARKzVmzwSMDdaP/hOB6i9ouKsIhN9hQUmUhbhaMkh7UXoxGW+gCSK
8dq0+FJVnlt1dtJByiVAJRi2oKSdLRqNjk8yGzuZ6SrEFzAgYZwmQiywUF6V1ZaM
UQDz8+nr9OOVU3c6Z2IQXCbOv6S7TAg0VhriFL18ZxUPS6759SuKC63VOOSf4EEH
y1m0qBgpCzzlsB7D4ssF9x0ZVXLREFrqikP71Hg6tSGcu4YBKL+VwIDWWaXzz6sz
xeDXdYTA3l35P7I9uBUgMznIjTjNaAX4AXRsJcN9fpF7mVq4eK1CorBY+OOzOc+/
yVBpKysdaV/yZ+ABEhX93B2kPLFSOPUKjSPK2rtqE6h2NSl5BFuGEoVBerKn+ymO
nmE4/SDBSe5S6gIL5vwy5zNMsxWUaUF5XO9Ez+2v8+yPSvQydj3pw5Rlb07mAXcI
18ZYGClO6g/aKL52KYnn1FZ/X3r8r/cibfDbuXC6FRfVXJmzikVUqZdTp0tOwPkh
4V0R63l2RO9Luy7vG6rurANSFnUA9n842KkRtBagQeQC96dbC0ebhTj+NPmskklx
r6/6Op/P7d+YY76WzvQMvnsCAwEAAQ==
-----END PUBLIC KEY-----`
var MYKU_APP_KEY = `txCR5732xYYWDGdd49M3R19o1OVwdRFc`

func EncryptWithRSAPublicKey(text string, pubKey *rsa.PublicKey) (string, error) {
	label := []byte("")
	hash := sha1.New()
	encrypted, err := rsa.EncryptOAEP(hash, rand.Reader, pubKey, []byte(text), label)
	if err != nil {
		return "", err
	}
	return base64.StdEncoding.EncodeToString(encrypted), nil
}

func Login(c *fiber.Ctx) error {

	const SecretKey = "secret"

	var data map[string]string

	if err := c.BodyParser(&data); err != nil {
		return err
	}

	// Parse RSA public key
	block, _ := pem.Decode([]byte(MYKU_RSA_PUBLIC_KEY))
	if block == nil || block.Type != "PUBLIC KEY" {
		fmt.Println("Failed to decode PEM block containing public key")
		return nil
	}
	pubKey, err := x509.ParsePKIXPublicKey(block.Bytes)
	if err != nil {
		fmt.Println("Failed to parse RSA public key:", err)
		return err
	}
	rsaPubKey, ok := pubKey.(*rsa.PublicKey)
	if !ok {
		fmt.Println("Invalid RSA public key")
		return err
	}

	encryptedUsername, err := EncryptWithRSAPublicKey(data["username"], rsaPubKey)
	if err != nil {
		fmt.Println("Failed to encrypt username:", err)
		return err
	}
	encryptedPassword, err := EncryptWithRSAPublicKey(data["password"], rsaPubKey)
	if err != nil {
		fmt.Println("Failed to encrypt password:", err)
		return err
	}

	baseURL := "https://myapi.ku.th"
	endpoint := "/auth/login"

	payload, err := json.Marshal(map[string]string{
		"username": encryptedUsername,
		"password": encryptedPassword,
	})
	if err != nil {
		fmt.Println("Failed to marshal payload:", err)
		return err
	}

	client := &http.Client{}
	req, err := http.NewRequest("POST", baseURL+endpoint, bytes.NewBuffer(payload))
	if err != nil {
		fmt.Println("Failed to create request:", err)
		return err
	}
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("App-Key", MYKU_APP_KEY)
	req.Header.Set("Origin", "https://my.ku.th")
	req.Header.Set("Referer", "https://my.ku.th/")

	resp, err := client.Do(req)
	if err != nil {
		fmt.Println("Failed to make POST request:", err)
		return err
	}
	defer resp.Body.Close()

	var response map[string]interface{}
	err = json.NewDecoder(resp.Body).Decode(&response)
	if err != nil {
		fmt.Println("Failed to decode JSON response:", err)
		return err
	}


	if(response["code"] != "success") {
		return c.JSON(fiber.Map{
			"message":     "failed to login",
		})
	}

	userMyku, ok := response["user"].(map[string]interface{})
	if !ok {
		fmt.Println("User field not found or not in the expected format")
		return err
	}

	var user models.User

	database.DB.Where("std_code = ?", userMyku["idCode"]).First(&user)




	idCode, ok := userMyku["idCode"].(string)
	if !ok {
		fmt.Println("idCode field not found or not a string")
		return err
	}
	
	database.DB.Where("std_code = ?", idCode).First(&user)
	
	if user.Id == 0 {
		// Generate a random and unique love ID
		heartId, err := generateRandomHeartId()
		if err != nil {
			return err
		}
	
		// Convert interface{} fields to strings
		firstName, _ := userMyku["firstNameEn"].(string)
		middleName, _ := userMyku["middleNameEn"].(string)
		lastName, _ := userMyku["lastNameEn"].(string)
	
		user := models.User{
			StdCode:    idCode,
			FirstName:  firstName,
			MiddleName: middleName,
			LastName:   lastName,
			HeartId:    heartId,
			IsActive:   true,
			LastActive: time.Now().Unix(),
		}
	
		database.DB.Create(&user)
	}

	database.DB.Where("std_code = ?", userMyku["stdCode"]).First(&user)

	claims := jwt.NewWithClaims(jwt.SigningMethodHS256, jwt.MapClaims{
		"id":          user.Id,
		"std_code":    user.StdCode,
		"first_name":  user.FirstName,
		"middle_name": user.MiddleName,
		"last_name":   user.LastName,
		"heart_id":    user.HeartId,
		"is_active":   user.IsActive,
		"last_active": user.LastActive,
		"exp":         time.Now().Add(time.Hour * 24).Unix(), // 1 day
		"iss":         strconv.Itoa(int(user.Id)),
	})

	token, err := claims.SignedString([]byte(SecretKey))
	if err != nil {
		c.SendStatus(fiber.StatusInternalServerError)

		return c.JSON(fiber.Map{
			"message": "could not login",
		})
	}

	return c.JSON(fiber.Map{
		"code":     "success",
		"accesstoken": token,
	})
}

func generateRandomHeartId() (string, error) {
	// Generate a random number within the range of 10 digits
	randomNum, err := rand.Int(rand.Reader, big.NewInt(10000000000)) // 10^10 = 10000000000
	if err != nil {
		return "", err
	}

	// Convert the random number to a string
	heartId := fmt.Sprintf("%010d", randomNum)

	return heartId, nil
}

func User(c *fiber.Ctx) error {
	var users []models.User

	database.DB.Find(&users)

	return c.JSON(users)
}

func Logout(c *fiber.Ctx) error {
	cookie := fiber.Cookie{
		Name:     "jwt",
		Value:    "",
		Expires:  time.Now().Add(-time.Hour),
		HTTPOnly: true,
	}

	c.Cookie(&cookie)

	return c.JSON(fiber.Map{
		"message": "success",
	})
}

func UpdateUserProfile(c *fiber.Ctx) error {
	userId := c.Params("userId")

	// Parse the JSON body to extract the new bio content
	var data map[string]string
	if err := c.BodyParser(&data); err != nil {
		return err
	}

	// Retrieve the user from the database
	var user models.User
	if err := database.DB.Where("id = ?", userId).First(&user).Error; err != nil {
		return err
	}

	// Update the user's bio
	user.Bio = data["bio"]
	user.ImagePath = data["image_path"]
	if err := database.DB.Save(&user).Error; err != nil {
		return err
	}

	return c.JSON(fiber.Map{
		"message": "User data updated successfully",
	})
}
