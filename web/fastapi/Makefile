dev:
	uvicorn main:app --reload --port 8080

live:
	gunicorn main:app -D --pid PID --config=gunicorn.py -k uvicorn.workers.UvicornWorker 

kill:
	sudo kill `cat PID`

install:
	python3 -m pip install -r requirements.txt
