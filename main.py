import mysql.connector
from mysql.connector import Error


def enter_user():
    try:
        global username
        print("enter your username")
        username = input()
        print("enter your password")
        password = input()
        args = [username, password, 0]
        message = cursor.callproc("enter_user", args)
        print(message[2])
        db.commit()
        return message[len(message) - 1]
    except Error as e:
        print(e)


time_show = "%Y-%m%d %H:%M:%S"


def get_notification():
    try:
        cursor.callproc("get_notification")
        print("owner_user\t\tbody\t\ttime")
        for j in cursor.stored_results():
            for result in j:
                i = 0
                while i < len(result):
                    if i == 2:
                        print(result[i].strftime(time_show))
                    else:
                        print(result[i], end="\t\t")
                    i += 1
                print()
        print()

    except Error as e:
        print(e)
    except Exception as ex:
        print(ex)


def get_my_information():
    global username
    try:
        cursor.callproc("get_information", [username])

        print("username\t\taddress\t\tfirstname\t\tlastname\t\tphone\t\tbirthdate\t\tnickname\t\tid\t\tflag",
              end="\t\t")
        print("password\t\tdate created\t\t related phone")
        for j in cursor.stored_results():
            for result in j:
                i = 0
                while i < len(result):
                    if i == 10:
                        print(result[i].strftime(time_show), end="\t\t")
                    else:
                        print(result[i], end="\t\t")
                    i += 1
                print()
        print()
    except Error as e:
        print(e)
    except Exception as ex:
        print(ex)


def get_information():
    user = input("enter the username to get information : ")
    try:
        cursor.callproc("get_information", [user])

        print("username\t\taddress\t\tfirstname\t\tlastname\t\tphone\t\tbirthdate\t\tnickname\t\tid\t\tflag")
        for j in cursor.stored_results():
            for result in j:
                i = 0
                while i < len(result):
                    print(result[i], end="\t\t")
                    i += 1
                print()
        print()
    except Error as e:
        print(e)
    except Exception as ex:
        print(ex)


def specific_allow():
    try:
        print("enter username which you want to set specific allow")
        user = input()
        print("if you want to allow that account to see your personal information enter 1, else enter 0")
        allow = input()
        args = [user, allow, 0]
        message = cursor.callproc("set_specific_allow", args)
        print(message[2])
        db.commit()
    except Error as e:
        print(e)


def delete_email():
    try:
        id = int(input("enter the id of the email : "))
        message = cursor.callproc("delete_email", [id, 0])
        print(message[len(message) - 1])
        db.commit()

    except Error as e:
        print(e)
    except Exception as ex:
        print(ex)


def get_email():
    try:
        id = int(input("enter the id of the email : "))
        message = cursor.callproc("get_email", [id, 0])
        if message[len(message) - 1] == "successful":
            print("id\t\tsender user\t\tsubject\t\tbody\t\tsent time\t\treceiver user\t\tcc\t\tis_read")
            for j in cursor.stored_results():
                for result in j:
                    i = 0
                    while i < len(result):
                        if i == 4:
                            print(result[i].strftime(time_show), end="\t\t")
                        else:
                            print(result[i], end="\t\t")
                        i += 1
                    print()
            print()
            db.commit()
        else:
            print(message[len(message) - 1])

    except Error as e:
        print(e)
    except Exception as ex:
        print(ex)


def get_sent_emails():
    try:
        page = int(input("which page do you want to see?"))
        cursor.callproc("get_sent_emails", [page])
        print("id\t\tsubject\t\tbody\t\tsent time\t\treceiver user\t\tcc")
        for j in cursor.stored_results():
            for result in j:
                i = 0
                while i < len(result):
                    if i == 3:
                        print(result[i].strftime(time_show), end="\t\t")
                    else:
                        print(result[i], end="\t\t")
                    i += 1
                print()
        print()

    except Error as e:
        print(e)
    except Exception as ex:
        print(ex)


def send_email():
    print("enter subject")
    subject = input()
    print("enter body")
    body = input()
    print("enter receivers")
    receivers = input()
    print("enter receivers CC, if you don't have one, put space")
    receivers_cc = input()
    args = [subject, body, receivers, receivers_cc, 0]
    message = cursor.callproc("send_email", args)
    print(message[len(message) - 1], "\n")
    db.commit()


def delete_account():
    print("Are you sure you want to delete account, if yes enter 1")
    input1 = input()
    if input1 == "1":
        try:
            cursor.callproc("delete_account")
            db.commit()
            return False
        except Error as e:
            print(e)
        except Exception as ex:
            print(ex)
    return True


def get_inbox_email():
    try:
        page = int(input("which page do you want to see? "))
        cursor.callproc("get_inbox_email", [page])
        print("id\t\tsender user\t\tsubject\t\tbody\t\tsent time\t\tcc\t\tis read")
        for j in cursor.stored_results():
            for result in j:
                i = 0
                while i < len(result):
                    if i == 4:
                        print(result[i].strftime(time_show), end="\t\t")
                    else:
                        print(result[i], end="\t\t")
                    i += 1
                print()
        print()

    except Error as e:
        print(e)
    except Exception as ex:
        print(ex)


def update_user():
    try:
        print("enter address")
        address = input()
        print("enter firstname")
        name = input()
        print("enter lastname")
        lastname = input()
        print("enter phone")
        phone = input()
        print("enter nickname")
        nickname = input()
        print("enter birthdate")
        birthdate = input()
        print("enter id")
        id = input()
        print("enter the phone that is related to your account")
        related_phone = input()
        print("enter password")
        password = input()
        print("if you want your personal information to be seen by others enter 1, else enter 0")
        flag = input()
        args = [address, name, lastname, phone, related_phone, birthdate, nickname,
                id, flag, password, 0]
        message = cursor.callproc("update_user", args)
        print(message[len(message) - 1], "\n")
        db.commit()

    except Error as e:
        print(e)


def create_user():
    try:
        print("enter username")
        username = input()
        print("enter address")
        address = input()
        print("enter firstname")
        name = input()
        print("enter lastname")
        lastname = input()
        print("enter birthdate")
        birthdate = input()
        print("enter nickname")
        nickname = input()
        print("enter phone")
        phone = input()
        print("enter id")
        id = input()
        print("enter the phone that is related to your account")
        related_phone = input()
        print("enter password")
        password = input()
        args = [username, address, name, lastname, birthdate, nickname, phone, id, related_phone, password, 0]
        message = cursor.callproc("create_user", args)
        print(message[len(message) - 1], "\n")
        db.commit()

    except Error as e:
        print(e)


cursor = None
db = None
username = None

if __name__ == "__main__":
    db = mysql.connector.connect(host='localhost', user="Atieh", password="Atieh", database="foofle")

    cursor = db.cursor()

    while True:
        print("If you want to create account enter 1, if you want to login to your account enter 2")
        enter = input()
        if enter == "1":
            create_user()
        elif enter == "2":
            result = enter_user()
            if result == "Enter was successfull!":
                flag = True
                while flag:
                    print("As you desire, enter the code:\nget notifications : 1\nget inbox : 2\nget sent emails : 3")
                    print("get email by id : 4\nsend email : 5\nget your system and personal information : 6")
                    print("get sb's personal information : 7\ndelete email by id : 8\nupdate your account : 9")
                    print("set specific allow to a user : 10")
                    print("delete account : 11, exit : 12")
                    enter = input()
                    if enter == '1':
                        get_notification()
                    elif enter == '2':
                        get_inbox_email()
                    elif enter == '3':
                        get_sent_emails()
                    elif enter == '4':
                        get_email()
                    elif enter == '5':
                        send_email()
                    elif enter == '6':
                        get_my_information()
                    elif enter == '7':
                        get_information()
                    elif enter == '8':
                        delete_email()
                    elif enter == '9':
                        update_user()
                    elif enter == '10':
                        specific_allow()
                    elif enter == '11':
                        flag = delete_account()
                    elif enter == '12':
                        flag = False
                    else:
                        print("Wrong Input, try again!")

        else:
            print("Wrong Input, try again!")
