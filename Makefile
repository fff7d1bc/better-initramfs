all:
	@echo '>>> Try make help'
help:
	@scripts/meta help
image:
	@scripts/meta image
image_no_gz:
	@scripts/meta image_no_gz
clean:
	@scripts/meta clean
prepare:
	@scripts/meta prepare
gen_sshd_keys:
	@scripts/meta gen_sshd_keys
release:
	@scripts/release
bootstrap-all:
	@bootstrap/bootstrap-all $(filter-out $@,$(MAKECMDGOALS))
